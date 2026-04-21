import React from "react";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import Navbar from "./components/Navbar";
import MatchesPage from "./pages/MatchesPage";
import InterestsPage from "./pages/InterestsPage";
import AuthPage from "./pages/AuthPage";
import { useAuth } from "./hooks/useAuth";
import VerifyEmailPage from "./pages/VerifyEmailPage";
import ResetPasswordPage from "./pages/ResetPasswordPage";
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

const ProtectedRoute: React.FC<React.PropsWithChildren> = ({ children }) => {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return <PlaceholderPage title="loading" />;
  }

  if (!isAuthenticated) {
    return <Navigate to="/" replace />;
  }

  return <>{children}</>;
};

const App: React.FC = () => {
  const { logout, isAuthenticated } = useAuth();

  const handleSignOut = () => {
    logout();
  };

  
  return (
    <BrowserRouter>
      <Navbar onSignOut={isAuthenticated ? handleSignOut : undefined} />
      <Routes>
        <Route path="/verify-email" element={<VerifyEmailPage />} />
        <Route path="/reset-password" element={<ResetPasswordPage />} />
        <Route path="/" element={<AuthPage />} />
        <Route path="/how-it-works" element={<PlaceholderPage title="how it works" />} />
        <Route path="/interests" element={<ProtectedRoute><InterestsPage /></ProtectedRoute>} />
        <Route path="/matches" element={<ProtectedRoute><MatchesPage /></ProtectedRoute>} />
        <Route path="/chat" element={<Navigate to="/matches" replace />} />
        <Route path="*" element={<Navigate to="/" replace />} />
      
      </Routes>
    </BrowserRouter>
  );
};


export default App;