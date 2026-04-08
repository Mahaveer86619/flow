import re

with open("ytmusic-api/frontend/index.html", "r", encoding="utf-8") as f:
    text = f.read()

# Replace sidebar CSS
old_sidebar_css = """            /* Sidebar Player */
            .sidebar {
                width: 380px;
                background: var(--surface);
                border-left: 1px solid var(--border);
                display: flex;
                flex-direction: column;
                align-items: center;
                padding: 32px 24px;
                transform: translateX(100%);
                transition:
                    transform 0.3s cubic-bezier(0.4, 0, 0.2, 1),
                    background 0.5s ease;
                position: fixed;
                right: 0;
                top: 0;
                bottom: 0;
                z-index: 40;
                box-shadow: -4px 0 24px rgba(0, 0, 0, 0.5);
            }
            .sidebar.active {
                transform: translateX(0);
            }"""

new_sidebar_css = """            /* Sidebar Player */
            .sidebar {
                width: 380px;
                background: var(--surface);
                border-left: 1px solid var(--border);
                display: flex;
                flex-direction: column;
                align-items: center;
                padding: 32px 24px;
                margin-right: -380px;
                opacity: 0;
                transition:
                    margin-right 0.4s cubic-bezier(0.2, 0.8, 0.2, 1),
                    opacity 0.2s,
                    background 0.5s ease;
                z-index: 40;
                flex-shrink: 0;
                box-shadow: -8px 0 32px rgba(0, 0, 0, 0.4);
            }
            .sidebar.active {
                margin-right: 0;
                opacity: 1;
            }"""

if old_sidebar_css in text:
    text = text.replace(old_sidebar_css, new_sidebar_css)
else:
    print("WARNING: Sidebar CSS not found exactly.")


# Enhance .card CSS
old_card_css = """            .card {
                background: transparent;
                border-radius: var(--radius);
                overflow: hidden;
                cursor: pointer;
                transition: all 0.2s;
                position: relative;
                display: flex;
                flex-direction: column;
            }
            .card:hover {
                transform: translateY(-4px);
            }"""

new_card_css = """            .card {
                background: transparent;
                border-radius: var(--radius);
                overflow: hidden;
                cursor: pointer;
                transition: transform 0.3s cubic-bezier(0.2, 0.8, 0.2, 1), box-shadow 0.3s;
                position: relative;
                display: flex;
                flex-direction: column;
            }
            .card:hover {
                transform: translateY(-8px) scale(1.02);
            }
            .card::after {
                content: '';
                position: absolute;
                inset: 0;
                border-radius: var(--radius);
                border: 1px solid rgba(255,255,255,0.05);
                pointer-events: none;
            }"""

if old_card_css in text:
    text = text.replace(old_card_css, new_card_css)
else:
    print("WARNING: Card CSS not found exactly.")


# Add hero banner css before "/* Main Area */"
hero_css = """
            .hero-banner {
                background: linear-gradient(135deg, rgba(139, 92, 246, 0.15) 0%, rgba(236, 72, 153, 0.15) 100%);
                border-radius: 24px;
                padding: 48px;
                margin-bottom: 40px;
                display: flex;
                flex-direction: column;
                justify-content: center;
                position: relative;
                overflow: hidden;
                border: 1px solid rgba(255, 255, 255, 0.05);
            }
            .hero-banner::before {
                content: '';
                position: absolute;
                top: -50%; left: -50%; width: 200%; height: 200%;
                background: radial-gradient(circle, rgba(139, 92, 246, 0.15) 0%, transparent 50%);
                animation: spinBlob 20s linear infinite;
            }
            @keyframes spinBlob {
                0% { transform: rotate(0deg); }
                100% { transform: rotate(360deg); }
            }
            .hero-title {
                font-size: 3rem;
                font-weight: 800;
                margin-bottom: 8px;
                position: relative;
                z-index: 1;
                letter-spacing: -1px;
            }
            .hero-subtitle {
                font-size: 1.2rem;
                color: var(--muted);
                position: relative;
                z-index: 1;
            }

            /* Main Area */"""

text = text.replace("            /* Main Area */", hero_css)


# Add hero banner to HTML
old_home_html = """            <!-- Home View -->
            <main id="home" class="view active">
                <div id="section-title">Home Feed</div>"""

new_home_html = """            <!-- Home View -->
            <main id="home" class="view active">
                <div class="hero-banner">
                    <div class="hero-title">Discover the Best Music</div>
                    <div class="hero-subtitle">Listen to hand-picked playlists, top albums, and your favorite artists.</div>
                </div>
                <div id="section-title">Explore</div>"""

if old_home_html in text:
    text = text.replace(old_home_html, new_home_html)
else:
    print("WARNING: Home HTML not found exactly.")


with open("ytmusic-api/frontend/index.html", "w", encoding="utf-8") as f:
    f.write(text)

print("Done")
