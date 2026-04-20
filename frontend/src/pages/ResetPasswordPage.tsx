import React, { useState } from "react";
import { useSearchParams, useNavigate } from "react-router-dom";

const SERVER_URL = import.meta.env.VITE_API_URL;

const ResetPasswordPage: React.FC = () => {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [done, setDone] = useState(false);

  const token = searchParams.get("token");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!password.trim()) { setError("Password is required."); return; }
    if (password.length < 8) { setError("Password must be at least 8 characters."); return; }
    if (password !== confirmPassword) { setError("Passwords do not match."); return; }
    if (!token) { setError("Invalid reset link."); return; }

    setIsLoading(true);
    try {
      const res = await fetch(`${SERVER_URL}/api/auth/reset-password`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ token, password }),
      });
      const data = await res.json();
      if (data.error) { setError(data.error); return; }
      setDone(true);
      setTimeout(() => navigate("/", { replace: true }), 2000);
    } catch {
      setError("Something went wrong. Please try again.");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-[var(--color-bg)]">
      <div className="max-w-md w-full px-8 flex flex-col gap-6">
        <h1 className="text-2xl font-semibold tracking-tight text-[var(--color-text-primary)]"
          style={{ fontFamily: "var(--font-display)" }}>
          hot take<span className="text-[var(--color-accent-red)]">.</span>
        </h1>

        {done ? (
          <p className="text-sm text-[var(--color-text-primary)]">
            ✓ password updated! redirecting you to sign in...
          </p>
        ) : (
          <>
            <div>
              <h2 className="text-xl font-normal lowercase text-[var(--color-text-primary)] mb-1">
                reset password
              </h2>
              <p className="text-sm text-[var(--color-text-muted)]">enter your new password below.</p>
            </div>

            <form onSubmit={handleSubmit} className="flex flex-col gap-4">
              <div>
                <label className="mb-2 block text-[10px] font-light uppercase tracking-[0.2em] text-[#888780]">
                  NEW PASSWORD
                </label>
                <input
                  type="password"
                  value={password}
                  onChange={(e) => { setPassword(e.target.value); setError(null); }}
                  className="w-full rounded-lg border border-[#D3D1C7] bg-[#F7F7F5] px-4 py-3 text-[#888780] outline-none transition focus:border-[#EF9F27]"
                />
              </div>

              <div>
                <label className="mb-2 block text-[10px] font-light uppercase tracking-[0.2em] text-[#888780]">
                  CONFIRM PASSWORD
                </label>
                <input
                  type="password"
                  value={confirmPassword}
                  onChange={(e) => { setConfirmPassword(e.target.value); setError(null); }}
                  className="w-full rounded-lg border border-[#D3D1C7] bg-[#F7F7F5] px-4 py-3 text-[#888780] outline-none transition focus:border-[#EF9F27]"
                />
              </div>

              {error && <p className="text-sm text-[#B02A2A]">{error}</p>}

              <button
                type="submit"
                disabled={isLoading}
                className="w-full rounded-full bg-[#E24B4A] px-4 py-3 text-sm font-normal lowercase text-white transition hover:shadow-[0_6px_0_#4A1B0C] active:translate-y-[1px]"
              >
                {isLoading ? "updating..." : "update password"}
              </button>
            </form>
          </>
        )}
      </div>
    </div>
  );
};

export default ResetPasswordPage;