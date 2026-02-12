let playing = false;

// Cache DOM elements
const app = document.getElementById("app");
const linkInput = document.getElementById("link");
const title = document.getElementById("title");
const artist = document.getElementById("artist");
const album = document.getElementById("album");
const bar = document.getElementById("bar");
const playPauseBtn = document.getElementById("playpause");

// Listen for messages from Lua
window.addEventListener("message", (e) => {
    if (e.data.action === "show") {
        app.style.display = "block";
    }

    if (e.data.action === "hide") {
        app.style.display = "none";
    }

    if (e.data.action === "progress") {
        const pct = (e.data.current / e.data.duration) * 100;
        bar.style.width = pct + "%";
    }
});

// Play / Pause
function toggle() {
    playing = !playing;
    playPauseBtn.innerText = playing ? "❚❚" : "▶";

    fetch(`https://${GetParentResourceName()}/${playing ? "resume" : "pause"}`, {
        method: "POST"
    });
}

// Progress bar update
window.addEventListener("message", (e) => {
    if (e.data.action === "progress" && playing) { // Only update if playing
        const pct = (e.data.current / e.data.duration) * 100;
        bar.style.width = pct + "%";
    }

    if (e.data.action === "show") app.style.display = "block";
    if (e.data.action === "hide") app.style.display = "none";
});

// Submit song
function submit() {
    const link = linkInput.value;
    if (!link) return;

    fetch(`https://${GetParentResourceName()}/play`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            link,
            playId: Date.now() // 🔥 forces Lua to treat it as a new song
        })
    });

    // Metadata (unchanged)
    fetch(`https://noembed.com/embed?url=${encodeURIComponent(link)}`)
        .then(r => r.json())
        .then(d => {
            title.innerText = d.title || "Unknown";
            artist.innerText = d.author_name || "";
            album.src = d.thumbnail_url || "";
        })
        .catch(() => {
            title.innerText = "Unknown";
            artist.innerText = "";
            album.src = "";
        });

    playing = true;
    playPauseBtn.innerText = "❚❚";
}

// Volume
function vol(v) {
    fetch(`https://${GetParentResourceName()}/volume`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ vol: parseFloat(v) })
    });
}

// Close UI
function closeUI() {
    fetch(`https://${GetParentResourceName()}/close`, { method: "POST" });
    app.style.display = "none";
}
