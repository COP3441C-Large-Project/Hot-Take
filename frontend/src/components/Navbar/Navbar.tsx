import React from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
// Adjust this path to wherever your AuthContext/Provider file lives
import { useAuth } from "../../hooks/useAuth"; 

const NAV_LINKS = [
  { label: "home", href: "/", protected: false },
  { label: "interests", href: "/interests", protected: true },
  { label: "matches", href: "/matches", protected: true },
  { label: "chat", href: "/chat", protected: true },
];

const Navbar: React.FC = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const { logout, isAuthenticated } = useAuth();

  const handleSignOut = (e: React.MouseEvent) => {
    e.preventDefault();
    logout();      // Clears the token/state
    navigate("/"); // Forces the screen to move to home/login
  };

  return (
    <nav className="flex items-center gap-8 px-8 h-14 border-b border-[var(--color-border)] sticky top-0 z-50 bg-[var(--color-bg)]">
      <Link
        to="/"
        className="font-mono text-[1.1rem] font-semibold tracking-tight text-[var(--color-text-primary)] no-underline shrink-0"
        style={{ fontFamily: "var(--font-display)" }}
      >
        hot take<span className="text-[var(--color-accent-red)]">.</span>
      </Link>

      <ul className="flex list-none gap-1 flex-1 m-0 p-0">
        {NAV_LINKS.map((link) => {
          // Hide protected links if the user isn't logged in
          if (link.protected && !isAuthenticated) return null;

          return (
            <li key={link.href}>
              <Link
                to={link.href}
                className={`text-sm px-3 py-1.5 rounded-md no-underline transition-colors duration-150 ${
                  location.pathname === link.href
                    ? "text-[var(--color-accent-red)]"
                    : "text-[var(--color-text-secondary)] hover:text-[var(--color-text-primary)] hover:bg-[var(--color-surface-hover)]"
                }`}
                style={{ fontFamily: "var(--font-body)" }}
              >
                {link.label}
              </Link>
            </li>
          );
        })}
      </ul>

      {/* Only show sign out button if authenticated */}
      {isAuthenticated && (
        <button
          onClick={handleSignOut}
          type="button"
          className="text-[0.8rem] text-[var(--color-text-secondary)] bg-transparent border border-[var(--color-border-strong)] rounded-md px-3.5 py-1.5 cursor-pointer shrink-0 transition-all duration-150 hover:text-[var(--color-text-primary)] hover:border-[var(--color-text-secondary)] hover:bg-[var(--color-surface-hover)]"
          style={{ fontFamily: "var(--font-body)" }}
        >
          sign out
        </button>
      )}
    </nav>
  );
};

export default Navbar;