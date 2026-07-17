from __future__ import annotations

from typing import Any

import httpx
from fastapi import BackgroundTasks, FastAPI, HTTPException, Request
from fastapi.responses import HTMLResponse
from pydantic import BaseModel, ConfigDict, Field

from whatsapp_service.agent_client import PaneninAgentClient
from whatsapp_service.config import get_whatsapp_settings
from whatsapp_service.demo_agent import DemoAgentClient
from whatsapp_service.engine import ConversationEngine
from whatsapp_service.security import derive_channel_subject, verify_webhook_secret

settings = get_whatsapp_settings()
app = FastAPI(title="Panenin WhatsApp Service", version="0.1.0")
engine = ConversationEngine(PaneninAgentClient(settings))
demo_engine = ConversationEngine(DemoAgentClient())


class DemoMessage(BaseModel):
    model_config = ConfigDict(populate_by_name=True)

    session_id: str = Field(
        default="browser-demo",
        alias="sessionId",
        min_length=3,
        max_length=80,
    )
    message: str = Field(min_length=1, max_length=1000)


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok", "service": "panenin-whatsapp"}


@app.post("/webhook/fonnte")
async def fonnte_webhook(
    request: Request,
    background_tasks: BackgroundTasks,
) -> dict[str, Any]:
    payload = await _read_payload(request)
    presented_secret = str(
        payload.get("secret")
        or request.headers.get("X-Webhook-Secret")
        or request.query_params.get("secret")
        or ""
    )
    configured_secret = settings.fonnte_webhook_secret.get_secret_value()
    if not verify_webhook_secret(presented_secret, configured_secret):
        raise HTTPException(status_code=401, detail="Webhook tidak valid.")
    sender = str(payload.get("sender", "")).strip()
    message = str(payload.get("message") or payload.get("text") or "").strip()
    if not sender or not message:
        return {"status": True, "ignored": True}
    if sender.endswith("@g.us"):
        return {"status": True, "ignored": True}
    inbox_id = str(payload.get("inboxid", "")).strip() or None
    background_tasks.add_task(_process_and_reply, sender, message, inbox_id)
    return {"status": True}


@app.get("/demo", response_class=HTMLResponse)
async def demo_page() -> str:
    if not settings.whatsapp_demo_ui_enabled or settings.app_env == "production":
        raise HTTPException(status_code=404)
    return _DEMO_HTML


@app.post("/demo/message")
async def demo_message(payload: DemoMessage) -> dict[str, str]:
    if not settings.whatsapp_demo_ui_enabled or settings.app_env == "production":
        raise HTTPException(status_code=404)
    subject = derive_channel_subject(payload.session_id, "panenin-local-demo")
    return {"reply": await demo_engine.handle(subject, payload.message)}


async def _process_and_reply(
    sender: str,
    message: str,
    inbox_id: str | None,
) -> None:
    try:
        subject = derive_channel_subject(
            sender,
            settings.whatsapp_subject_pepper.get_secret_value(),
        )
        reply = await engine.handle(subject, message)
    except Exception:
        # The provider gets a safe response without leaking tokens, sender, or internals.
        reply = "Maaf, layanan Panenin sedang mengalami gangguan. Coba lagi sebentar."
    try:
        await _send_fonnte(sender, reply, inbox_id)
    except httpx.HTTPError:
        # Fonnte retries the inbound webhook independently. A failed outbound
        # send must not leak provider details or crash the worker.
        return


async def _send_fonnte(
    target: str,
    message: str,
    inbox_id: str | None,
) -> None:
    token = settings.fonnte_token.get_secret_value().strip()
    if not token:
        return
    data: dict[str, str] = {
        "target": target,
        "message": message,
        "countryCode": "62",
    }
    if inbox_id:
        data["inboxid"] = inbox_id
    async with httpx.AsyncClient(timeout=20.0) as client:
        response = await client.post(
            f"{settings.fonnte_api_url.rstrip('/')}/send",
            headers={"Authorization": token},
            data=data,
        )
        response.raise_for_status()


async def _read_payload(request: Request) -> dict[str, Any]:
    content_type = request.headers.get("content-type", "")
    if "application/json" in content_type:
        value = await request.json()
        return value if isinstance(value, dict) else {}
    form = await request.form()
    return dict(form)


_DEMO_HTML = """<!doctype html>
<html lang="id">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Panenin Bot Demo</title>
  <style>
    *{box-sizing:border-box} body{margin:0;background:#efeae2;font:15px/1.4 Arial,sans-serif;color:#18221c}
    .phone{max-width:430px;height:100vh;margin:auto;background:#efeae2;display:flex;flex-direction:column;box-shadow:0 0 24px #0002}
    header{padding:14px 16px;background:#176b45;color:white;font-weight:700;font-size:18px}
    header small{display:block;font-size:12px;font-weight:400;opacity:.85}
    #chat{flex:1;overflow:auto;padding:16px;display:flex;flex-direction:column;gap:10px}
    .bubble{max-width:88%;padding:10px 12px;border-radius:10px;white-space:pre-wrap;box-shadow:0 1px 2px #0002}
    .bot{background:white;align-self:flex-start}.me{background:#d9fdd3;align-self:flex-end}
    .quick{padding:8px 10px;display:flex;gap:6px;overflow:auto;background:#f7f7f7}
    .quick button{white-space:nowrap;border:1px solid #176b45;background:white;color:#176b45;border-radius:16px;padding:7px 10px}
    form{display:flex;gap:8px;padding:10px;background:white} input{flex:1;border:1px solid #ccd3ce;border-radius:20px;padding:11px 14px}
    form button{border:0;border-radius:50%;width:42px;background:#176b45;color:white;font-size:17px}
  </style>
</head>
<body><main class="phone">
  <header>Panenin Bot <small>simulator remote control</small></header>
  <section id="chat"><div class="bubble bot">Ketik HUBUNGKAN DEMO12 untuk memulai demo.</div></section>
  <nav class="quick">
    <button data-msg="HUBUNGKAN DEMO12">Hubungkan</button><button data-msg="STATUS">Status</button>
    <button data-msg="STOK">Stok</button><button data-msg="PESANAN">Pesanan</button>
    <button data-msg="UBAH STOK 1 32">Ubah stok</button><button data-msg="TERIMA 1">Terima</button>
    <button data-msg="KONFIRMASI 123456">Konfirmasi</button>
  </nav>
  <form id="form"><input id="message" autocomplete="off" placeholder="Ketik pesan"><button>➤</button></form>
</main>
<script>
const chat=document.querySelector('#chat'),input=document.querySelector('#message');
async function send(message){if(!message)return;add(message,'me');input.value='';
 const r=await fetch('/demo/message',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify({sessionId:'browser-demo',message})});
 const data=await r.json();add(data.reply||'Gagal memproses pesan.','bot')}
function add(text,kind){const el=document.createElement('div');el.className='bubble '+kind;el.textContent=text.replaceAll('*','');chat.append(el);chat.scrollTop=chat.scrollHeight}
document.querySelector('#form').onsubmit=e=>{e.preventDefault();send(input.value)};
document.querySelectorAll('[data-msg]').forEach(b=>b.onclick=()=>send(b.dataset.msg));
</script></body></html>"""
