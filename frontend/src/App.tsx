import React from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import Navbar from "./components/Navbar";
import MatchesPage from "./pages/MatchesPage";
import InterestsPage from "./pages/InterestsPage";
import "./index.css";

const PlaceholderPage: React.FC<{ title: string }> = ({ title }) => (
  <div
    style={{
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      height: "calc(100vh - 56px)",
      fontFamily: "var(--font-display)",
      fontSize: "1rem",
      color: "var(--text-muted)",
    }}
  >
    {title} — coming soon
  </div>
);

const App: React.FC = () => {
  const handleSignOut = () => {
    // call sign-out API and redirect
    // await fetch("/api/auth/signout", { method: "POST" });
    // window.location.href = "/login";
  };

  
  return (
    <BrowserRouter>
      <Navbar onSignOut={handleSignOut} />
      <Routes>
        <Route path="/" element={<PlaceholderPage title="home" />} />
        <Route path="/how-it-works" element={<PlaceholderPage title="how it works" />} />
        <Route path="/interests" element={<InterestsPage />} />
        <Route path="/matches" element={<MatchesPage />} />
        <Route path="/chat" element={<Navigate to="/matches" replace />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  );
};


export default App;