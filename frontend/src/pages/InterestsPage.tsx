import React, { useState } from "react";
import {useNavigate} from "react-router-dom";

const SUGGESTIONS = ["cooking", "music", "climate", "gaming", "politics", "startups"];

const PalmTree: React.FC<{ flip?: boolean }> = ({ flip = false }) => (
  <svg
    viewBox="0 0 200 400"
    width="220"
    height="440"
    style={{ transform: flip ? "scaleX(-1)" : undefined }}
    xmlns="http://www.w3.org/2000/svg"
  >
    {/* Trunk */}
    <path
      d="M95 400 C90 350 85 300 88 250 C90 200 95 150 100 100"
      stroke="#5a3e1b"
      strokeWidth="14"
      fill="none"
      strokeLinecap="round"
    />
    {/* Fronds */}
    <path d="M100 100 C60 60 10 50 -10 20" stroke="#2d6a2d" strokeWidth="8" fill="none" strokeLinecap="round"/>
    <path d="M100 100 C140 60 190 50 210 20" stroke="#2d6a2d" strokeWidth="8" fill="none" strokeLinecap="round"/>
    <path d="M100 100 C80 50 70 0 60 -20" stroke="#2d6a2d" strokeWidth="8" fill="none" strokeLinecap="round"/>
    <path d="M100 100 C120 50 130 0 140 -20" stroke="#2d6a2d" strokeWidth="8" fill="none" strokeLinecap="round"/>
    <path d="M100 100 C50 80 20 90 -10 80" stroke="#2d6a2d" strokeWidth="8" fill="none" strokeLinecap="round"/>
    <path d="M100 100 C150 80 180 90 210 80" stroke="#2d6a2d" strokeWidth="8" fill="none" strokeLinecap="round"/>
    <path d="M100 100 C90 70 85 40 75 20" stroke="#3a8a3a" strokeWidth="6" fill="none" strokeLinecap="round"/>
    <path d="M100 100 C110 70 115 40 125 20" stroke="#3a8a3a" strokeWidth="6" fill="none" strokeLinecap="round"/>
    {/* Coconuts */}
    <circle cx="96" cy="108" r="7" fill="#8B6914"/>
    <circle cx="108" cy="112" r="7" fill="#7a5c10"/>
    <circle cx="100" cy="118" r="7" fill="#8B6914"/>
  </svg>
);

const InterestsPage: React.FC = () => {
  const [bio, setBio] = useState("");
  const [tags, setTags] = useState<string[]>([]);
  const [tagInput, setTagInput] = useState("");
  const [tagError, setTagError] = useState("");
  const [paradiseMode, setParadiseMode] = useState(false);
  const navigate = useNavigate();
  const [leineckerMode, setLeineckerMode] = useState(false);

  const addTag = (tag: string) => {
    const cleaned = tag.trim().toLowerCase();
    if (cleaned === "") return;
    if (cleaned.length > 30) {
      setTagError("tags must be 30 characters or fewer.");
      return;
    }
    if (tags.length >= 10) {
      setTagError("you can only add up to 10 tags.");
      return;
    }
    if (tags.includes(cleaned)) {
      setTagError(`"${cleaned}" is already added.`);
      return;
    }
    setTagError("");
    if (cleaned === "leinecker") setLeineckerMode(true);
    if (cleaned === "paradise") setParadiseMode(true);
    setTags([...tags, cleaned]);
  };

  const removeTag = (tag: string) => {
    if (tag === "leinecker") setLeineckerMode(false);
    if (tag === "paradise") setParadiseMode(false);
    setTags(tags.filter((t) => t !== tag));
  };

  const handleTagKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Enter") {
      e.preventDefault();
      addTag(tagInput);
      setTagInput("");
    }
  };

  const bgStyle = paradiseMode
    ? { background: "linear-gradient(to bottom, #f4845f, #f7b46a, #f5d08a)" }
    : { background: "#ffffff" };

  const handleSubmit = async () => {
  try {
    const token = localStorage.getItem("token");
    const response = await fetch("http://localhost:3001/api/interests", {
      method: "PUT",
      headers: {
        "Authorization": `Bearer ${token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ bio, tags }),
    });
    if (response.ok) {
      navigate("/matches");
    } else {
      console.error("Failed to save interests:", response.status);
    }
  } catch (err) {
    console.error("Error submitting interests:", err);
  }
};

  return (
    <div
      className="min-h-screen px-10 py-10 relative overflow-hidden transition-all duration-700"
      style={bgStyle}
    >
      {/* Palm trees — only visible in paradise mode */}
      {paradiseMode && (
        <>
          <div className="fixed bottom-0 left-0 z-0 pointer-events-none">
            <PalmTree />
          </div>
          <div className="fixed bottom-0 right-0 z-0 pointer-events-none">
            <PalmTree flip />
          </div>
        </>
      )}

      {/* Paradise banner */}
      {paradiseMode && (
        <div className="relative z-10 text-center mb-6 text-white font-bold tracking-widest text-sm font-[var(--font-display)] animate-pulse">
          🌴 paradise mode unlocked 🌴
        </div>
      )}

      <div className="max-w-5xl mx-auto flex gap-10 relative z-10">

        {/* Left column */}
        <div className="flex-1 flex flex-col gap-6">

          {/* Heading + subtitle */}
          <div className="flex flex-col gap-1">
            <h1 className="text-3xl font-bold font-[var(--font-display)]">
              {paradiseMode ? "what's on your mind? 🌴" : "what's on your mind?"}
            </h1>
            <p className="italic text-sm text-[var(--text-muted)]">
              {paradiseMode
                ? "welcome to paradise. tell us your vibe."
                : "this is how we find your people. be honest, be specific."}
            </p>
          </div>

          {/* Textarea */}
          <div className="relative">
            <textarea
              className="w-full h-48 rounded-2xl bg-gray-100 px-4 py-3 text-sm resize-none focus:outline-none focus:ring-2 focus:ring-blue-400"
              placeholder="Placeholder text here"
              maxLength={500}
              value={bio}
              onChange={(e) => setBio(e.target.value)}
            />
            <span className="absolute bottom-3 right-4 text-xs text-[var(--text-muted)]">
              {bio.length}/500
            </span>
          </div>

          {/* Tag input */}
          <div className="flex flex-col gap-2">
            <label className="text-xs font-bold tracking-widest text-[var(--text-muted)]">
              INTEREST TAGS
            </label>
            <input
              className="w-full rounded-2xl bg-gray-100 px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-400"
              placeholder="type and press Enter"
              value={tagInput}
              onChange={(e) => setTagInput(e.target.value)}
              onKeyDown={handleTagKeyDown}
            />

            {/* Error message */}
            {tagError && (
              <p className="text-xs text-rose-500">{tagError}</p>
            )}

            {/* Tag pills */}
            <div className="flex flex-wrap gap-2">
              {tags.map((tag) => (
                <span
                  key={tag}
                  className="flex items-center gap-1 px-3 py-1 rounded-full bg-rose-100 text-rose-500 text-xs"
                >
                  {tag}
                  <button
                    onClick={() => removeTag(tag)}
                    className="hover:text-rose-700"
                  >
                    ×
                  </button>
                </span>
              ))}
            </div>
          </div>

          {/* Suggestions */}
          <div className="flex flex-col gap-2">
            <label className="text-xs font-bold tracking-widest text-[var(--text-muted)]">
              SUGGESTIONS
            </label>
            <div className="flex flex-wrap gap-2">
              {SUGGESTIONS.map((s) => (
                <button
                  key={s}
                  onClick={() => addTag(s)}
                  className="px-3 py-1 rounded-full border border-gray-300 text-xs text-[var(--text-muted)] hover:border-gray-400"
                >
                  + {s}
                </button>
              ))}
            </div>
          </div>
          
          {/* Submit button */}
          <button
            onClick={handleSubmit}
            className="w-full py-3 rounded-2xl bg-amber-400 hover:bg-amber-500 text-white font-bold text-sm tracking-wide transition-colors duration-200"
          >
            find my matches →
          </button>
        </div>

        {/* Right sidebar */}
    <div className="w-72 shrink-0">
      <div className="rounded-2xl border border-gray-200 p-5 flex flex-col gap-4">

        {/* Sidebar title */}
        <h2 className="text-xs font-bold font-[var(--font-display)] tracking-widest">
          tips for better matches
        </h2>
        <hr className="border-gray-200" />

        {/* Tip 1 */}
        <div className="flex flex-col gap-1 border-l-4 border-rose-400 pl-3">
          <p className="text-xs font-bold font-[var(--font-display)]">be specific, not generic</p>
          <p className="text-xs italic text-[var(--text-muted)]">
            Not "music" — "alt rock and music composition"
          </p>
        </div>

        {/* Tip 2 */}
        <div className="flex flex-col gap-1 border-l-4 border-amber-400 pl-3">
          <p className="text-xs font-bold font-[var(--font-display)]">share your current obsessions</p>
          <p className="text-xs italic text-[var(--text-muted)]">
            What can you not stop thinking about?
          </p>
        </div>

        {/* Tip 3 */}
        <div className="flex flex-col gap-1 border-l-4 border-rose-400 pl-3">
          <p className="text-xs font-bold font-[var(--font-display)]">include your hot takes</p>
          <p className="text-xs italic text-[var(--text-muted)]">
            Strong opinions attract interesting people.
          </p>
        </div>

        <hr className="border-gray-200" />

        {/* Footer note */}
        <p className="text-xs text-[var(--text-muted)] font-[var(--font-display)]">
          up to 10 tags · 500 character bio
        </p>

        {/* Leinecker easter egg */}
        {leineckerMode && (
          <div className="flex flex-col items-center gap-2">
            <hr className="border-gray-200 w-full" />
            <img
              src="/leinecker.png"
              alt="Dr. Leinecker"
              className="rounded-xl w-full object-cover"
            />
            <p className="text-xs text-center italic text-[var(--text-muted)] font-[var(--font-display)]">
              🤿 found the professor
            </p>
          </div>
        )}
          </div>
        </div>

      </div>
    </div>
  );
};

export default InterestsPage;