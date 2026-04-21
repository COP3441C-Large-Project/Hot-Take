import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../hooks/useAuth";
import { apiClient } from "../services/apiClient";

const SUGGESTIONS = ["cooking", "music", "climate", "gaming", "politics", "startups"];

const PalmTree: React.FC<{ flip?: boolean }> = ({ flip = false }) => (
  <svg
    viewBox="0 0 200 400"
    width="220"
    height="440"
    style={{ transform: flip ? "scaleX(-1)" : undefined }}
    xmlns="http://www.w3.org/2000/svg"
  >
    <path
      d="M95 400 C90 350 85 300 88 250 C90 200 95 150 100 100"
      stroke="#5a3e1b"
      strokeWidth="14"
      fill="none"
      strokeLinecap="round"
    />
    <path d="M100 100 C60 60 10 50 -10 20" stroke="#2d6a2d" strokeWidth="8" fill="none" strokeLinecap="round"/>
    <path d="M100 100 C140 60 190 50 210 20" stroke="#2d6a2d" strokeWidth="8" fill="none" strokeLinecap="round"/>
    <path d="M100 100 C80 50 70 0 60 -20" stroke="#2d6a2d" strokeWidth="8" fill="none" strokeLinecap="round"/>
    <path d="M100 100 C120 50 130 0 140 -20" stroke="#2d6a2d" strokeWidth="8" fill="none" strokeLinecap="round"/>
    <path d="M100 100 C50 80 20 90 -10 80" stroke="#2d6a2d" strokeWidth="8" fill="none" strokeLinecap="round"/>
    <path d="M100 100 C150 80 180 90 210 80" stroke="#2d6a2d" strokeWidth="8" fill="none" strokeLinecap="round"/>
    <path d="M100 100 C90 70 85 40 75 20" stroke="#3a8a3a" strokeWidth="6" fill="none" strokeLinecap="round"/>
    <path d="M100 100 C110 70 115 40 125 20" stroke="#3a8a3a" strokeWidth="6" fill="none" strokeLinecap="round"/>
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
  const [leineckerMode, setLeineckerMode] = useState(false);
  const [isLoading, setIsLoading] = useState(false); // New loading state
  
  const navigate = useNavigate();
  const { token } = useAuth();

  // Load existing data on mount
  useEffect(() => {
    if (!token) return;
    const loadExisting = async () => {
      try {
        const data = await apiClient.get<{ bio: string; tags: string[] }>("/api/interests", token);
        if (data.bio) setBio(data.bio);
        if (data.tags) {
            setTags(data.tags);
            if (data.tags.includes("paradise")) setParadiseMode(true);
            if (data.tags.includes("leinecker")) setLeineckerMode(true);
        }
      } catch (err) {
        console.error("No existing interests found");
      }
    };
    loadExisting();
  }, [token]);

  const addTag = (tag: string) => {
    const cleaned = tag.trim().toLowerCase();
    if (cleaned === "" || tags.includes(cleaned) || tags.length >= 10) return;
    if (cleaned.length > 30) {
      setTagError("tags must be 30 characters or fewer.");
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

  const handleSubmit = async () => {
  if (!token) {
    navigate("/");
    return;
  }

  setIsLoading(true);
  
  // Fire and forget — don't await
  apiClient.put("/api/interests", { bio, tags }, token).catch((err) => {
    console.error("Failed to save interests:", err);
  });

  // Navigate after 2 seconds no matter what
  setTimeout(() => navigate("/matches"), 2000);
};

  const bgStyle = paradiseMode
    ? { background: "linear-gradient(to bottom, #f4845f, #f7b46a, #f5d08a)" }
    : { background: "#ffffff" };

  return (
    <div
      className="min-h-screen px-10 py-10 relative overflow-hidden transition-all duration-700"
      style={bgStyle}
    >
      {/* LOADING POPUP OVERLAY */}
      {isLoading && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/40 backdrop-blur-md animate-in fade-in duration-300">
          <div className="bg-white p-10 rounded-3xl shadow-2xl flex flex-col items-center gap-6 max-w-sm text-center">
            <div className="relative">
                <div className="w-16 h-16 border-4 border-amber-100 rounded-full"></div>
                <div className="w-16 h-16 border-4 border-amber-500 border-t-transparent rounded-full animate-spin absolute top-0 left-0"></div>
            </div>
            <div>
                <h2 className="text-2xl font-bold font-[var(--font-display)] text-gray-900">Finding matches...</h2>
                <p className="text-sm text-gray-500 italic mt-2">Hang tight while we find the best people for you.</p>
            </div>
          </div>
        </div>
      )}

      {paradiseMode && (
        <>
          <div className="fixed bottom-0 left-0 z-0 pointer-events-none">
            <PalmTree />
          </div>
          <div className="fixed bottom-0 right-0 z-0 pointer-events-none">
            <PalmTree flip />
          </div>
          <div className="relative z-10 text-center mb-6 text-white font-bold tracking-widest text-sm font-[var(--font-display)] animate-pulse">
            🌴 paradise mode unlocked 🌴
          </div>
        </>
      )}

      <div className="max-w-5xl mx-auto flex gap-10 relative z-10">
        {/* Left column */}
        <div className="flex-1 flex flex-col gap-6">
          <div className="flex flex-col gap-1">
            <h1 className="text-3xl font-bold font-[var(--font-display)] text-gray-900">
              {paradiseMode ? "what's on your mind? 🌴" : "what's on your mind?"}
            </h1>
            <p className="italic text-sm text-gray-500">
              {paradiseMode
                ? "welcome to paradise. tell us your vibe."
                : "this is how we find your people. be honest, be specific."}
            </p>
          </div>

          <div className="relative">
            <textarea
              className="w-full h-48 rounded-2xl bg-gray-100 px-4 py-3 text-sm resize-none focus:outline-none focus:ring-2 focus:ring-blue-400 text-gray-800"
              placeholder="Tell us about yourself..."
              maxLength={500}
              value={bio}
              onChange={(e) => setBio(e.target.value)}
            />
            <span className="absolute bottom-3 right-4 text-xs text-gray-400">
              {bio.length}/500
            </span>
          </div>

          <div className="flex flex-col gap-2">
            <label className="text-xs font-bold tracking-widest text-gray-400 uppercase">
              INTEREST TAGS
            </label>
            <input
              className="w-full rounded-2xl bg-gray-100 px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-400 text-gray-800"
              placeholder="type and press Enter"
              value={tagInput}
              onChange={(e) => setTagInput(e.target.value)}
              onKeyDown={handleTagKeyDown}
            />
            {tagError && <p className="text-xs text-rose-500">{tagError}</p>}

            <div className="flex flex-wrap gap-2">
              {tags.map((tag) => (
                <span
                  key={tag}
                  className="flex items-center gap-1 px-3 py-1 rounded-full bg-rose-100 text-rose-500 text-xs font-medium"
                >
                  {tag}
                  <button onClick={() => removeTag(tag)} className="hover:text-rose-700">×</button>
                </span>
              ))}
            </div>
          </div>

          <div className="flex flex-col gap-2">
            <label className="text-xs font-bold tracking-widest text-gray-400 uppercase">
              SUGGESTIONS
            </label>
            <div className="flex flex-wrap gap-2">
              {SUGGESTIONS.map((s) => (
                <button
                  key={s}
                  onClick={() => addTag(s)}
                  className="px-3 py-1 rounded-full border border-gray-300 text-xs text-gray-500 hover:border-gray-400 hover:bg-gray-50 transition-colors"
                >
                  + {s}
                </button>
              ))}
            </div>
          </div>
          
          <button
            onClick={handleSubmit}
            disabled={isLoading}
            className={`w-full py-3 rounded-2xl font-bold text-sm tracking-wide transition-all duration-200 ${
                isLoading 
                ? "bg-gray-300 text-gray-500 cursor-not-allowed" 
                : "bg-amber-400 hover:bg-amber-500 text-white shadow-md hover:shadow-lg"
            }`}
          >
            {isLoading ? "analyzing vibe..." : "find my matches →"}
          </button>
        </div>

        {/* Right sidebar */}
        <div className="w-72 shrink-0">
          <div className="rounded-2xl border border-gray-200 bg-white/50 backdrop-blur-sm p-5 flex flex-col gap-4">
            <h2 className="text-xs font-bold font-[var(--font-display)] tracking-widest text-gray-900 uppercase">
              tips for better matches
            </h2>
            <hr className="border-gray-100" />

            <div className="flex flex-col gap-1 border-l-4 border-rose-400 pl-3 text-gray-800">
              <p className="text-xs font-bold">be specific, not generic</p>
              <p className="text-xs italic text-gray-500">Not "music" — "alt rock and music composition"</p>
            </div>

            <div className="flex flex-col gap-1 border-l-4 border-amber-400 pl-3 text-gray-800">
              <p className="text-xs font-bold">share your current obsessions</p>
              <p className="text-xs italic text-gray-500">What can you not stop thinking about?</p>
            </div>

            <div className="flex flex-col gap-1 border-l-4 border-rose-400 pl-3 text-gray-800">
              <p className="text-xs font-bold">include your hot takes</p>
              <p className="text-xs italic text-gray-500">Strong opinions attract interesting people.</p>
            </div>

            <hr className="border-gray-100" />
            <p className="text-xs text-gray-400 font-[var(--font-display)]">
              up to 10 tags · 500 character bio
            </p>

            {leineckerMode && (
              <div className="flex flex-col items-center gap-2 animate-in slide-in-from-bottom-4 duration-500">
                <hr className="border-gray-100 w-full" />
                <img src="/leinecker.png" alt="Dr. Leinecker" className="rounded-xl w-full object-cover shadow-sm" />
                <p className="text-xs text-center italic text-gray-500 font-[var(--font-display)]">
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