# Flow — The Ultimate Music Ecosystem 🎵

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)

Flow is a high-performance, self-hosted music streaming ecosystem. It bridges the gap between the vast library of YouTube Music and a premium, private listening experience. With a sleek Flutter frontend and a robust Python backend, Flow gives you total control over your music.

---

## ✨ Key Features

- **💎 Premium UI/UX:** Material 3 design with dynamic color extraction, squiggly progress bars, and fluid animations.
- **🌍 Cross-Platform:** Native performance on Android, iOS, Windows, macOS, and Linux.
- **🛡️ Self-Hosted Privacy:** You own the server, you own the data. No tracking, no middleman.
- **🚀 High-Performance Streaming:** Proxied audio delivery with range-request support for instant seeking and minimal buffering.
- **sync Integrated Library:** Access your YouTube Music playlists, history, and liked songs seamlessly.
- **🖥️ Desktop Excellence:** Full integration with System Media Transport Controls (SMTC) and media keys.

---

## 🏗️ Ecosystem Architecture

Flow is split into two main components:

1.  **[Flow App (Frontend)](./flow):** A beautiful Flutter-based client for all your devices.
2.  **[Flow Source (Backend)](./flow-source):** A containerized FastAPI server that handles authentication, metadata, and audio proxying.

---

## 🚀 Quick Start Guide

Deploying your private music cloud is simple. Follow these steps to get up and running.

### 1. Fire up the Backend
The easiest way to run the backend is using Docker Compose.

```bash
cd flow-source
docker-compose up -d
```

#### 🛠️ Connecting from the Internet (The Tunnel)
The backend includes a **Cloudflare Tunnel**. This allows you to access your server from your phone without complex port forwarding or static IPs.

1.  Run `docker-compose logs -f tunnel`.
2.  Look for a URL ending in `.trycloudflare.com`.
3.  **Keep this URL handy;** you'll need it for the app setup.

### 2. Configure and Run the App
Now, connect the Flutter app to your newly created server.

1.  Navigate to the app directory: `cd flow`.
2.  Create a `.env` file (copy from `.env.example`):
    ```env
    API_BASE_URL=https://your-tunnel-url.trycloudflare.com
    ```
3.  Install dependencies and run:
    ```bash
    flutter pub get
    flutter run
    ```

---

## 📖 Detailed Documentation

| Component | Description | Guide |
| :--- | :--- | :--- |
| **Frontend** | Flutter App, State Management, UI Components | [App README](./flow/README.md) |
| **Backend** | FastAPI, Database Schema, Streaming Logic | [Server README](./flow-source/README.md) |
| **API** | Endpoints and Authentication | [Postman Collection](./flow-source/Flow_v1_Postman_Collection.json) |

---

## 🤝 Contributing

We welcome contributions! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<p align="center">Made with ❤️ for music lovers.</p>
