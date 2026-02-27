// ==============================
// Global State
// ==============================
window.playing = false;
window.queue = [];
window.currentSong = null;

const app = document.getElementById("app");
const mainUI = document.getElementById("mainUI");
const linkInput = document.getElementById("link");
const title = document.getElementById("title");
const artist = document.getElementById("artist");
const album = document.getElementById("album");
const bar = document.getElementById("bar");
const playPauseBtn = document.getElementById("playpause");
const queuePanel = document.getElementById("queuePanel");
const queueList = document.getElementById("queueList");

// ==============================
// NUI Listener
// ==============================
window.addEventListener("message", (e) => {
    const data = e.data;

    switch (data.action) {

        case "show":
            app.style.display = "flex";
            mainUI.style.display = "block";
            queuePanel.style.display = "block";
            break;

        case "hide":
            app.style.display = "none";
            mainUI.style.display = "none";
            queuePanel.style.display = "none";
            break;

        case "progress":
            if (!data.duration || data.duration <= 0) return;
            bar.style.width = (data.current / data.duration) * 100 + "%";
            break;

        case "nowPlaying":
            window.currentSong = data.song || {};
            window.playing = true;

            title.innerText = window.currentSong.title || "Unknown Title";
            artist.innerText = window.currentSong.artist || "Unknown Artist";
            album.src = window.currentSong.thumbnail || "";

            playPauseBtn.innerText = "❚❚";
            bar.style.width = "0%";
            break;

        case "stop":
            window.currentSong = null;
            window.playing = false;
            playPauseBtn.innerText = "▶";
            bar.style.width = "0%";
            break;

        case "updateQueue":
            if (!window.queue || window.queue.length !== (data.queue || []).length) {
                window.queue = data.queue || [];
                updateQueueUI();
            }
            break;
    }
});

// ==============================
// Play Song
// ==============================
function playSong(song) {
    fetch(`https://${GetParentResourceName()}/play`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(song)
    });
}

// ==============================
// Queue UI
// ==============================
function updateQueueUI() {

    if (!queueList) return;

    queueList.innerHTML = "";

    if (window.queue.length === 0) {
        queueList.innerHTML = `<p style="opacity:0.6;">Queue is empty</p>`;
        return;
    }

    window.queue.forEach((song, index) => {

        const item = document.createElement("div");
        item.className = "queue-item";

        item.innerHTML = `
            <span>${index + 1}. ${song.title}</span>
            <button onclick="removeFromQueue(${index})">✖</button>
        `;

        queueList.appendChild(item);
    });
}

// ==============================
// Remove Song From Queue
// ==============================
function removeFromQueue(index) {

    // remove locally immediately for responsive UI
    window.queue.splice(index, 1);
    updateQueueUI();

    // notify server
    fetch(`https://${GetParentResourceName()}/remove`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ index })
    });
}

// ==============================
// Play / Pause
// ==============================
function toggle() {

    if (!window.currentSong) return;

    window.playing = !window.playing;
    playPauseBtn.innerText = window.playing ? "❚❚" : "▶";

    fetch(`https://${GetParentResourceName()}/${window.playing ? "resume" : "pause"}`, {
        method: "POST"
    });
}

// ==============================
// Submit Song
// ==============================
function submit() {

    const link = linkInput.value;
    if (!link) return;

    fetch(`https://noembed.com/embed?url=${encodeURIComponent(link)}`)
        .then(r => r.json())
        .then(d => {

            const songData = {
                link: link,
                title: d.title || "Unknown Title",
                artist: d.author_name || "Unknown Artist",
                thumbnail: d.thumbnail_url || ""
            };

            playSong(songData);
            linkInput.value = "";
        })
        .catch(() => console.log("Invalid link"));
}

// ==============================
// Volume
// ==============================
function vol(v) {

    fetch(`https://${GetParentResourceName()}/volume`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ vol: parseFloat(v) })
    });
}

// ==============================
// Close UI
// ==============================
function closeUI() {

    fetch(`https://${GetParentResourceName()}/close`, { method: "POST" });

    app.style.display = "none";
    mainUI.style.display = "none";
    queuePanel.style.display = "none";
}

// ==============================
// Skip Song (Manual)
// ==============================
function skip() {

    fetch(`https://${GetParentResourceName()}/skip`, {
        method: "POST"
    });
}

// ==============================
updateQueueUI();
