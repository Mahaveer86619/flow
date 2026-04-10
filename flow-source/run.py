import asyncio
import os

import ngrok
import uvicorn
from app.config import settings


def start_ngrok():
    if settings.FLAVOR == "dev":
        if not settings.NGROK_AUTHTOKEN:
            print("\n" + "=" * 50)
            print("WARNING: FLAVOR is 'dev' but NGROK_AUTHTOKEN is missing!")
            print("Please set NGROK_AUTHTOKEN in your .env file.")
            print("=" * 50 + "\n")
            return

        try:
            # Connect to ngrok
            listener = ngrok.forward(settings.PORT, authtoken=settings.NGROK_AUTHTOKEN)

            # Pretty print the endpoint
            print("\n" + "╔" + "═" * 48 + "╗")
            print(f"║ {'NGROK TUNNEL ESTABLISHED':^46} ║")
            print("╠" + "═" * 48 + "╣")
            print(f"║ URL: {listener.url():<41} ║")
            print(f"║ Flavor: {settings.FLAVOR:<38} ║")
            print("╚" + "═" * 48 + "╝\n")

        except Exception as e:
            print(f"Failed to start ngrok: {e}")


if __name__ == "__main__":
    # Start ngrok if in dev flavor
    start_ngrok()

    # Run uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG if settings.FLAVOR == "local" else False,
    )
