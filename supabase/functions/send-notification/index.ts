import { createRemoteJWKSet, jwtVerify } from 'npm:jose@5.10.0';

const FIREBASE_PROJECT_ID = 'homecare-16c84';
const FIREBASE_ISSUER = `https://securetoken.google.com/${FIREBASE_PROJECT_ID}`;
const FIRESTORE_BASE = `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents`;
const ONESIGNAL_URL = 'https://api.onesignal.com/notifications?c=push';

const firebaseJwks = createRemoteJWKSet(
  new URL(
    'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com',
  ),
);

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

type JsonRecord = Record<string, unknown>;

type FirebaseField = {
  stringValue?: string;
  integerValue?: string;
  booleanValue?: boolean;
};

type FirestoreDocument = {
  fields?: Record<string, FirebaseField>;
};

function json(data: JsonRecord, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function fieldString(doc: FirestoreDocument, name: string): string | null {
  const field = doc.fields?.[name];
  if (!field) return null;
  return field.stringValue ?? field.integerValue ?? null;
}

async function verifyFirebaseToken(request: Request): Promise<string> {
  const authorization = request.headers.get('Authorization') ?? '';
  if (!authorization.startsWith('Bearer ')) {
    throw new Error('missing_authorization');
  }

  const token = authorization.substring('Bearer '.length).trim();
  if (!token) throw new Error('missing_token');

  const { payload } = await jwtVerify(token, firebaseJwks, {
    issuer: FIREBASE_ISSUER,
    audience: FIREBASE_PROJECT_ID,
  });

  const uid = typeof payload.sub === 'string' ? payload.sub : '';
  if (!uid) throw new Error('missing_uid');
  return uid;
}

async function getFirestoreDocument(
  path: string,
  firebaseToken: string,
): Promise<FirestoreDocument> {
  const response = await fetch(`${FIRESTORE_BASE}/${path}`, {
    headers: {
      Authorization: `Bearer ${firebaseToken}`,
    },
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`firestore_${response.status}: ${body}`);
  }

  return await response.json() as FirestoreDocument;
}

async function sendOneSignalNotification(payload: JsonRecord): Promise<void> {
  const appId = Deno.env.get('ONESIGNAL_APP_ID');
  const restApiKey = Deno.env.get('ONESIGNAL_REST_API_KEY');

  if (!appId || !restApiKey) {
    throw new Error('onesignal_secrets_missing');
  }

  const response = await fetch(ONESIGNAL_URL, {
    method: 'POST',
    headers: {
      Authorization: `Key ${restApiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      app_id: appId,
      target_channel: 'push',
      ...payload,
    }),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`onesignal_${response.status}: ${body}`);
  }
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (request.method !== 'POST') {
    return json({ error: 'method_not_allowed' }, 405);
  }

  try {
    const firebaseToken = (request.headers.get('Authorization') ?? '')
      .substring('Bearer '.length)
      .trim();
    const callerUid = await verifyFirebaseToken(request);
    const body = await request.json() as JsonRecord;
    const type = body.type?.toString();

    if (type === 'message') {
      const chatId = body.chatId?.toString() ?? '';
      const receiverId = body.receiverId?.toString() ?? '';
      const message = body.message?.toString() ?? '';

      if (!chatId || !receiverId || !message) {
        return json({ error: 'invalid_message_payload' }, 400);
      }

      const chat = await getFirestoreDocument(`chats/${encodeURIComponent(chatId)}`, firebaseToken);
      const clientId = fieldString(chat, 'clientId');
      const nurseId = fieldString(chat, 'nurseId');
      const bookingId = fieldString(chat, 'bookingId');

      const callerIsParticipant = callerUid === clientId || callerUid === nurseId;
      const receiverIsParticipant = receiverId === clientId || receiverId === nurseId;
      const receiverIsOtherSide = receiverId !== callerUid;

      if (!callerIsParticipant || !receiverIsParticipant || !receiverIsOtherSide) {
        return json({ error: 'not_chat_participant' }, 403);
      }

      await sendOneSignalNotification({
        headings: {
          en: 'New message',
          ar: 'رسالة جديدة',
        },
        contents: {
          en: message,
          ar: message,
        },
        include_aliases: {
          external_id: [receiverId],
        },
        custom_data: {
          type: 'message',
          chatId,
          bookingId: bookingId ?? '',
        },
      });

      return json({ success: true });
    }

    if (type === 'care_request') {
      const requestId = body.requestId?.toString() ?? '';
      if (!requestId) return json({ error: 'invalid_request_payload' }, 400);

      const careRequest = await getFirestoreDocument(
        `careRequests/${encodeURIComponent(requestId)}`,
        firebaseToken,
      );

      const clientId = fieldString(careRequest, 'clientId');
      const status = fieldString(careRequest, 'status');
      if (clientId !== callerUid) {
        return json({ error: 'not_request_owner' }, 403);
      }

      if (status != null && status != 'open') {
        return json({ error: 'request_not_open' }, 409);
      }

      const patientName = fieldString(careRequest, 'patientName') ?? 'حالة جديدة';
      const governorate = fieldString(careRequest, 'governorate') ?? '';
      const area = fieldString(careRequest, 'area') ?? '';
      const shiftHours = fieldString(careRequest, 'shiftHours') ?? '';

      const locationText = [governorate, area]
        .where((value) => value.isNotEmpty)
        .join(' - ');

      await sendOneSignalNotification({
        headings: {
          en: 'New care request',
          ar: 'طلب رعاية جديد',
        },
        contents: {
          en: `New request for ${patientName}${locationText ? ` - ${locationText}` : ''}`,
          ar: `طلب رعاية جديد للحالة ${patientName}${locationText ? ` - ${locationText}` : ''}${shiftHours ? ` - ${shiftHours} ساعة` : ''}`,
        },
        filters: [
          {
            field: 'tag',
            key: 'role',
            relation: '=',
            value: 'nurse',
          },
        ],
        custom_data: {
          type: 'care_request',
          requestId,
        },
      });

      return json({ success: true });
    }

    return json({ error: 'unsupported_type' }, 400);
  } catch (error) {
    console.error('send-notification error:', error);
    return json({ error: error instanceof Error ? error.message : 'internal_error' }, 500);
  }
});
