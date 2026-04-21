import React, { useState, useCallback, useEffect } from "react";
import { Match } from "../types";
import MatchList from "../components/MatchList/MatchList";
import ChatWindow from "../components/ChatWindow/ChatWindow";
import { useChat } from "../hooks/useChat";
import { useAuth } from "../hooks/useAuth";
import { apiClient } from "../services/apiClient";

const MatchesPage: React.FC = () => {
  const { token, user, isLoading: authLoading } = useAuth();

  const [matches, setMatches] = useState<Match[]>([]);
  const [selectedMatch, setSelectedMatch] = useState<Match | null>(null);
  const [chatId, setChatId] = useState<string | null>(null);
  const [activeSection, setActiveSection] = useState<"matches" | "interests">("matches");
  
  // State for the current user's own interests/bio
  const [userInterests, setUserInterests] = useState<{ bio: string; tags: string[] }>({
    bio: "",
    tags: [],
  });

  useEffect(() => {
    if (!token) return;

    const loadData = async () => {
      try {
        // 1. Load Matches
        const matchData = await apiClient.get<{ matches: any[] }>("/api/matches", token);
        const loadedMatches: Match[] = (matchData.matches ?? []).map((m: any) => ({
          id: m.userId,
          username: m.username,
          interests: m.tags ?? [],
          matchPercentage: Math.round(m.score),
          lastMessage: undefined,
          isOnline: false,
        }));
        setMatches(loadedMatches);

        // 2. Load User's Own Interests (to show in the Interests tab)
       const profileData = await apiClient.get<{ bio: string; tags: string[] }>("/api/interests", token);
    
        setUserInterests({
          bio: profileData.bio || "",
          tags: profileData.tags || [],
        });
        // Automatically open chat with first match if matches exist
        if (loadedMatches.length > 0 && !selectedMatch) {
          setSelectedMatch(loadedMatches[0]);
          const chatData = await apiClient.post<{ chatId: string }>(
            `/api/matches/${loadedMatches[0].id}/start-chat`,
            {},
            token
          );
          console.log("raw matches:", matchData.matches);
          if (chatData.chatId) setChatId(chatData.chatId);
        }
      } catch (err) {
        console.error("Failed to load page data:", err);
      }
    };

    void loadData();
  }, [token]);

  const handleSelectMatch = useCallback(async (match: Match) => {
    setSelectedMatch(match);
    setActiveSection("matches"); // Switch back to chat view when a match is clicked
    setChatId(null);

    if (!token) return;

    try {
      const data = await apiClient.post<{ chatId: string }>(
        `/api/matches/${match.id}/start-chat`,
        {},
        token
      );
      if (data.chatId) setChatId(data.chatId);
    } catch (err) {
      console.error("Failed to start chat:", err);
    }
  }, [token]);

  const { messages, sendMessage, connectionStatus, isTyping } = useChat({
    chatId,
    token: token ?? "",
    userId: user?.id ?? "",
  });

  if (authLoading) {
    return (
      <div className="flex h-[calc(100vh-56px)] items-center justify-center">
        <p className="text-sm italic text-[var(--color-text-muted)]">loading...</p>
      </div>
    );
  }

  return (
    <main className="flex h-[calc(100vh-56px)] overflow-hidden bg-[var(--color-bg)]">
      <MatchList
        matches={matches}
        selectedMatchId={selectedMatch?.id ?? null}
        onSelectMatch={handleSelectMatch}
        activeSection={activeSection}
        onSectionChange={setActiveSection}
      />

      <section className="flex-1 overflow-y-auto">
        {activeSection === "matches" ? (
          <ChatWindow
            match={selectedMatch}
            messages={messages}
            onSendMessage={sendMessage}
            isTyping={isTyping}
            connectionStatus={connectionStatus}
          />
        ) : (
          /* USER INTERESTS VIEW */
          <div className="p-10 max-w-2xl mx-auto">
            <h2 className="text-2xl font-bold mb-6 font-[var(--font-display)]">your profile vibe</h2>
            
            <div className="mb-8">
              <label className="text-xs font-bold tracking-widest text-[var(--color-text-muted)] uppercase">Your Bio</label>
              <div className="mt-2 p-4 rounded-2xl bg-gray-50 border border-gray-100 italic text-gray-700">
                {userInterests.bio || "No bio set yet."}
              </div>
            </div>

            <div>
              <label className="text-xs font-bold tracking-widest text-[var(--color-text-muted)] uppercase">Your Tags</label>
              <div className="flex flex-wrap gap-2 mt-3">
                {userInterests.tags.map((tag) => (
                  <span
                    key={tag}
                    className="px-3 py-1 rounded-full bg-amber-100 text-amber-700 text-xs font-medium"
                  >
                    #{tag}
                  </span>
                ))}
                {userInterests.tags.length === 0 && <p className="text-sm text-gray-400">No tags added.</p>}
              </div>
            </div>

            <button 
              onClick={() => window.location.href = '/interests'} // or use navigate()
              className="mt-10 text-sm font-bold text-rose-500 hover:underline"
            >
              edit my interests →
            </button>
          </div>
        )}
      </section>
    </main>
  );
};

export default MatchesPage;