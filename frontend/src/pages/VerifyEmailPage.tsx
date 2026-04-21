import React, { useEffect, useState } from "react";
import { useSearchParams, useNavigate } from "react-router-dom";
import { useAuth } from "../hooks/useAuth";

const SERVER_URL = import.meta.env.VITE_API_URL;

const VerifyEmailPage: React.FC = () => {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const { login } = useAuth();
  const [status, setStatus] = useState<"loading" | "success" | "error">("loading");
  const [message, setMessage] = useState("");

  useEffect(() => {
    console.log("VERIFY PAGE LOADED"); 

  const token = searchParams.get("token");
  console.log("TOKEN:", token); 
    if (!token) {
      setStatus("error");
      setMessage("Invalid verification link.");
      return;
    }

    fetch(`${SERVER_URL}/api/auth/verify-email`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ token }),
    })
      .then((r) => r.json())
      .then((data) => {
        if (data.error) {
          setStatus("error");
          setMessage(data.error);
          return;
        }
        localStorage.setItem("hot_take_token", data.token);
        setStatus("success");
        // Auto redirect to interests after 2 seconds
        setTimeout(() => navigate("/interests", { replace: true }), 2000);
      })
      .catch(() => {
        setStatus("error");
        setMessage("Something went wrong. Please try again.");
      });
  }, 
  []);
  

  return (
    <div className="min-h-screen flex items-center justify-center bg-[var(--color-bg)]">
      <div className="max-w-md w-full px-8 text-center flex flex-col items-center gap-4">
        <h1 className="text-2xl font-semibold tracking-tight text-[var(--color-text-primary)]"
          style={{ fontFamily: "var(--font-display)" }}>
          hot take<span className="text-[var(--color-accent-red)]">.</span>
        </h1>

        {status === "loading" && (
          <p className="text-sm italic text-[var(--color-text-muted)]">verifying your email...</p>
        )}

        {status === "success" && (
          <>
            <p className="text-sm text-[var(--color-text-primary)]">
              ✓ email verified! redirecting you...
            </p>
          </>
        )}

        {status === "error" && (
          <>
            <p className="text-sm text-[#B02A2A]">{message}</p>
            <button
              onClick={() => navigate("/", { replace: true })}
              className="text-sm text-[var(--color-text-secondary)] underline"
            >
              back to sign in
            </button>
          </>
        )}
      </div>
    </div>
  );
};

export default VerifyEmailPage;