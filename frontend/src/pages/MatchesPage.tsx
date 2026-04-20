import React, { useState, useCallback, useEffect, useRef } from "react";
import { Match } from "../types";
import MatchList from "../components/MatchList/MatchList";
import ChatWindow from "../components/ChatWindow/ChatWindow";
import { useChat } from "../hooks/useChat";
import { useAuth } from "../hooks/useAuth";

const SERVER_URL = import.meta.env.VITE_API_URL;

const MatchesPage: React.FC = () => {
  const { token, user, isLoading } = useAuth();

  const [matches, setMatches] = useState<Match[]>([]);
  const [selectedMatch, setSelectedMatch] = useState<Match | null>(null);
  const [chatId, setChatId] = useState<string | null>(null);
  const [activeSection, setActiveSection] = useState<"matches" | "interests">("matches");

  // Fetch matches and open first chat in one go
  useEffect(() => {
    if (!token) return;

    fetch(`${SERVER_URL}/api/matches`, {
      headers: { Authorization: `Bearer ${token}` },
    })
      .then((r) => r.json())
      .then(async (data) => {
        const loaded: Match[] = (data.matches ?? []).map((m: any) => ({
          id: m.userId,
          username: m.username,
          interests: m.tags ?? [],
          matchPercentage: Math.round(m.score),
          lastMessage: undefined,
          isOnline: false,
        }));
        setMatches(loaded);

        // Automatically open chat with first match
        if (loaded.length > 0) {
          setSelectedMatch(loaded[0]);
          const res = await fetch(`${SERVER_URL}/api/matches/${loaded[0].id}/start-chat`, {
            method: "POST",
            headers: { Authorization: `Bearer ${token}` },
          });
          const chatData = await res.json();
          if (chatData.chatId) setChatId(chatData.chatId);
        }
      })
      .catch(() => {});
  }, [token]);

  //When user clicks a match
  const handleSelectMatch = useCallback(async (match: Match) => {
    setSelectedMatch(match);
    setActiveSection("matches");
    setChatId(null);

    if (!token) return;

    const res = await fetch(`${SERVER_URL}/api/matches/${match.id}/start-chat`, {
      method: "POST",
      headers: { Authorization: `Bearer ${token}` },
    });
    const data = await res.json();
    if (data.chatId) setChatId(data.chatId);
  }, [token]);

  const { messages, sendMessage, connectionStatus, isTyping } = useChat({
    chatId,
    token: token ?? "",
    userId: user?.id ?? "",
  });

  if (isLoading) {
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
      <ChatWindow
        match={selectedMatch}
        messages={messages}
        onSendMessage={sendMessage}
        isTyping={isTyping}
        connectionStatus={connectionStatus}
      />
    </main>
  );
};

export default MatchesPage;