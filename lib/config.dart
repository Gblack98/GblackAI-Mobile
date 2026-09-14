// GblackAI API configuration

const String kApiBaseUrl = 'https://gblackai-api.vercel.app';
const Duration kRequestTimeout = Duration(seconds: 90);

// Wolof text-to-speech (Oolel-Voices, Soynade Research — Hugging Face Space).
// Called directly from the app: no gradio_client, no TTS logic on the backend.
const String kOolelSpaceUrl = 'https://soynade-research-oolel-voices-demo.hf.space';
const String kTtsApiName = 'generate_tts_audio';
const Duration kTtsRequestTimeout = Duration(seconds: 90);
