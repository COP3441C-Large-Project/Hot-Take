import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { ApiError } from "../services/apiClient";
import { useAuth } from "../hooks/useAuth";

type AuthTab = "login" | "register";
type AuthView = "main" | "forgot" | "forgot-sent";

interface AuthFormProps {
  activeTab: AuthTab;
  onTabChange: (tab: AuthTab) => void;
}

const SERVER_URL = "http://localhost:3001";

const AuthForm: React.FC<AuthFormProps> = ({ activeTab, onTabChange }) => {
  const navigate = useNavigate();
  const { login, register, isLoading, error, clearError } = useAuth();
  const [view, setView] = useState<AuthView>("main");
  const [username, setUsername] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [forgotEmail, setForgotEmail] = useState("");
  const [formError, setFormError] = useState<string | null>(null);
  const [isSending, setIsSending] = useState(false);
  // After register, show "check your email" state
  const [pendingVerification, setPendingVerification] = useState(false);

  const submitLabel = activeTab === "login" ? "sign in" : "create account";

  const resetAll = () => {
    setFormError(null);
    clearError();
  };

  const handleTabChange = (tab: AuthTab) => {
    resetAll();
    setView("main");
    setPendingVerification(false);
    onTabChange(tab);
  };

  const handleSubmit = async () => {
    resetAll();

    if (activeTab === "login") {
      if (!email.trim() || !password.trim()) {
        setFormError("Email and password are required.");
        return;
      }
      try {
        await login(email.trim(), password);
        navigate("/interests", { replace: true });
      } catch (err) {
        if (!(err instanceof ApiError)) setFormError("Unable to log in right now.");
      }
      return;
    }

    if (!username.trim() || !email.trim() || !password.trim()) {
      setFormError("Username, email, and password are required.");
      return;
    }
    if (password !== confirmPassword) {
      setFormError("Passwords do not match.");
      return;
    }

    try {
      const res = await fetch(`${SERVER_URL}/api/auth/register`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ username: username.trim(), email: email.trim(), password }),
      });
      const data = await res.json();
      if (data.error) { setFormError(data.error); return; }

      // Send verification email
      await fetch(`${SERVER_URL}/api/auth/send-verification`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ userId: data.user.id }),
      });

      setPendingVerification(true);
    } catch {
      setFormError("Unable to create account right now.");
    }
  };

  const handleForgotPassword = async () => {
    if (!forgotEmail.trim()) {
      setFormError("Email is required.");
      return;
    }
    setIsSending(true);
    setFormError(null);
    try {
      await fetch(`${SERVER_URL}/api/auth/forgot-password`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: forgotEmail.trim() }),
      });
      setView("forgot-sent");
    } catch {
      setFormError("Unable to send reset email right now.");
    } finally {
      setIsSending(false);
    }
  };

  // ── Pending email verification state ─────────────────────────────────────
  if (pendingVerification) {
    return (
      <div className="flex-1 min-h-screen flex items-start justify-center bg-white px-8 pt-20"
        style={{ backgroundImage: "linear-gradient(to right, rgba(0,0,0,0.06) 1px, transparent 1px), linear-gradient(to bottom, rgba(0,0,0,0.06) 1px, transparent 1px)", backgroundSize: "60px 60px" }}
      >
        <div className="flex w-full max-w-md flex-col gap-4 pt-8">
          <h2 className="text-3xl font-normal lowercase text-black">check your email</h2>
          <p className="text-sm text-[#888780]">
            we sent a verification link to <span className="text-black">{email}</span>.
            click it to activate your account.
          </p>
          <p className="text-xs italic text-[#888780]">
            didn't get it? check your spam folder or{" "}
            <button className="underline" onClick={() => setPendingVerification(false)}>
              try again
            </button>
            .
          </p>
        </div>
      </div>
    );
  }

  // ── Forgot password sent state ────────────────────────────────────────────
  if (view === "forgot-sent") {
    return (
      <div className="flex-1 min-h-screen flex items-start justify-center bg-white px-8 pt-20"
        style={{ backgroundImage: "linear-gradient(to right, rgba(0,0,0,0.06) 1px, transparent 1px), linear-gradient(to bottom, rgba(0,0,0,0.06) 1px, transparent 1px)", backgroundSize: "60px 60px" }}
      >
        <div className="flex w-full max-w-md flex-col gap-4 pt-8">
          <h2 className="text-3xl font-normal lowercase text-black">check your email</h2>
          <p className="text-sm text-[#888780]">
            if an account exists for <span className="text-black">{forgotEmail}</span>,
            we sent a password reset link. it expires in 1 hour.
          </p>
          <button
            className="text-sm text-[#888780] underline text-left"
            onClick={() => { setView("main"); setForgotEmail(""); }}
          >
            ← back to sign in
          </button>
        </div>
      </div>
    );
  }

  // ── Forgot password form ──────────────────────────────────────────────────
  if (view === "forgot") {
    return (
      <div className="flex-1 min-h-screen flex items-start justify-center bg-white px-8 pt-20"
        style={{ backgroundImage: "linear-gradient(to right, rgba(0,0,0,0.06) 1px, transparent 1px), linear-gradient(to bottom, rgba(0,0,0,0.06) 1px, transparent 1px)", backgroundSize: "60px 60px" }}
      >
        <div className="flex w-full max-w-md flex-col gap-6 pt-8">
          <div>
            <h2 className="text-3xl font-normal lowercase text-black mb-2">forgot password</h2>
            <p className="text-sm text-[#888780]">enter your email and we'll send a reset link.</p>
          </div>

          <div>
            <label className="mb-2 block text-[10px] font-light uppercase tracking-[0.2em] text-[#888780]">EMAIL</label>
            <input
              type="email"
              value={forgotEmail}
              onChange={(e) => { setForgotEmail(e.target.value); setFormError(null); }}
              placeholder="you@example.com"
              className="w-full rounded-lg border border-[#D3D1C7] bg-[#F7F7F5] px-4 py-3 text-[#888780] outline-none transition placeholder:text-[#888780] focus:border-[#EF9F27]"
            />
          </div>

          {formError && <p className="text-sm text-[#B02A2A]">{formError}</p>}

          <button
            onClick={handleForgotPassword}
            disabled={isSending}
            className="w-full rounded-full bg-[#E24B4A] px-4 py-3 text-sm font-normal lowercase text-white transition hover:shadow-[0_6px_0_#4A1B0C] active:translate-y-[1px]"
          >
            {isSending ? "sending..." : "send reset link"}
          </button>

          <button
            className="text-sm text-[#888780] underline text-left"
            onClick={() => { setView("main"); setFormError(null); }}
          >
            ← back to sign in
          </button>
        </div>
      </div>
    );
  }

  // ── Main login/register form ──────────────────────────────────────────────
  return (
    <div
      className="flex-1 min-h-screen flex items-start justify-center bg-white px-8 pt-20"
      style={{
        backgroundImage: "linear-gradient(to right, rgba(0, 0, 0, 0.06) 1px, transparent 1px), linear-gradient(to bottom, rgba(0, 0, 0, 0.06) 1px, transparent 1px)",
        backgroundSize: "60px 60px",
      }}
    >
      <div className="flex min-h-[calc(100vh-5rem)] w-full max-w-md flex-col">
        <h2 className="mb-8 text-3xl font-normal lowercase text-black">
          {activeTab === "login" ? "sign in" : "create account"}
        </h2>

        <div className="grid grid-cols-2 gap-2 rounded-xl bg-[#F1EFE8] p-1">
          <button type="button" onClick={() => handleTabChange("login")}
            className={`rounded-lg px-4 py-2 text-sm font-normal lowercase transition ${activeTab === "login" ? "bg-white text-black" : "bg-[#F1EFE8] text-[#888780]"}`}
          >sign in</button>
          <button type="button" onClick={() => handleTabChange("register")}
            className={`rounded-lg px-4 py-2 text-sm font-normal lowercase transition ${activeTab === "register" ? "bg-white text-black" : "bg-[#F1EFE8] text-[#888780]"}`}
          >register</button>
        </div>

        <form className="mt-10 space-y-4" onSubmit={(e) => { e.preventDefault(); void handleSubmit(); }}>
          <div>
            <label className="mb-2 block text-[10px] font-light uppercase tracking-[0.2em] text-[#888780]">
              {activeTab === "login" ? "EMAIL" : "USERNAME"}
            </label>
            <input
              type={activeTab === "login" ? "email" : "text"}
              value={activeTab === "login" ? email : username}
              onChange={(e) => { resetAll(); activeTab === "login" ? setEmail(e.target.value) : setUsername(e.target.value); }}
              placeholder={activeTab === "login" ? "you@example.com" : undefined}
              className="w-full rounded-lg border border-[#D3D1C7] bg-[#F7F7F5] px-4 py-3 text-[#888780] outline-none transition placeholder:text-[#888780] focus:border-[#EF9F27]"
            />
          </div>

          {activeTab === "register" && (
            <div>
              <label className="mb-2 block text-[10px] font-light uppercase tracking-[0.2em] text-[#888780]">EMAIL</label>
              <input type="email" placeholder="you@example.com" value={email}
                onChange={(e) => { resetAll(); setEmail(e.target.value); }}
                className="w-full rounded-lg border border-[#D3D1C7] bg-[#F7F7F5] px-4 py-3 text-[#888780] outline-none transition placeholder:text-[#888780] focus:border-[#EF9F27]"
              />
            </div>
          )}

          <div>
            <label className="mb-2 block text-[10px] font-light uppercase tracking-[0.2em] text-[#888780]">PASSWORD</label>
            <input type="password" value={password}
              onChange={(e) => { resetAll(); setPassword(e.target.value); }}
              className="w-full rounded-lg border border-[#D3D1C7] bg-[#F7F7F5] px-4 py-3 text-[#888780] outline-none transition placeholder:text-[#888780] focus:border-[#EF9F27]"
            />
          </div>

          {activeTab === "register" && (
            <div>
              <label className="mb-2 block text-[10px] font-light uppercase tracking-[0.2em] text-[#888780]">CONFIRM PASSWORD</label>
              <input type="password" value={confirmPassword}
                onChange={(e) => { resetAll(); setConfirmPassword(e.target.value); }}
                className="w-full rounded-lg border border-[#D3D1C7] bg-[#F7F7F5] px-4 py-3 text-[#888780] outline-none transition placeholder:text-[#888780] focus:border-[#EF9F27]"
              />
            </div>
          )}

          {(formError || error) && <p className="text-sm text-[#B02A2A]">{formError ?? error}</p>}

          <button type="submit" disabled={isLoading}
            className="mt-4 w-full rounded-full bg-[#E24B4A] px-4 py-3 text-sm font-normal lowercase text-white transition hover:bg-[#E24B4A] hover:text-white hover:shadow-[0_6px_0_#4A1B0C] active:bg-white active:text-black active:translate-y-[1px]"
          >
            {isLoading ? "working..." : submitLabel}
          </button>

          {activeTab === "login" && (
            <button type="button"
              className="w-full text-center text-xs text-[#888780] underline hover:text-black transition"
              onClick={() => { resetAll(); setView("forgot"); }}
            >
              forgot password?
            </button>
          )}

          <p className="mt-auto pt-8 text-center text-xs italic lowercase text-[#888780]">
            your identity is never shared with matches
          </p>
        </form>
      </div>
    </div>
  );
};

export default AuthForm;