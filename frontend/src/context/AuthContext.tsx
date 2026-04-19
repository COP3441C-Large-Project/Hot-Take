import React from "react";
import { apiClient, ApiError } from "../services/apiClient";
import { AuthResponse, AuthUser } from "../types";

interface AuthContextValue {
  user: AuthUser | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
  login: (email: string, password: string) => Promise<void>;
  register: (username: string, email: string, password: string) => Promise<void>;
  logout: () => void;
  clearError: () => void;
}

const TOKEN_KEY = "hot_take_token";

const AuthContext = React.createContext<AuthContextValue | undefined>(undefined);

export const AuthProvider: React.FC<React.PropsWithChildren> = ({ children }) => {
  const [user, setUser] = React.useState<AuthUser | null>(null);
  const [token, setToken] = React.useState<string | null>(null);
  const [isLoading, setIsLoading] = React.useState(true);
  const [error, setError] = React.useState<string | null>(null);

  const persistSession = React.useCallback((nextToken: string, nextUser: AuthUser) => {
    localStorage.setItem(TOKEN_KEY, nextToken);
    setToken(nextToken);
    setUser(nextUser);
  }, []);

  const clearSession = React.useCallback(() => {
    localStorage.removeItem(TOKEN_KEY);
    setToken(null);
    setUser(null);
  }, []);

  const clearError = React.useCallback(() => {
    setError(null);
  }, []);

  const handleAuthFailure = React.useCallback((message: string) => {
    clearSession();
    setError(message);
  }, [clearSession]);

  React.useEffect(() => {
    const boot = async () => {
      const savedToken = localStorage.getItem(TOKEN_KEY);

      if (!savedToken) {
        setIsLoading(false);
        return;
      }

      try {
        const response = await apiClient.get<{ user: AuthUser }>("/api/me", savedToken);
        setToken(savedToken);
        setUser(response.user);
      } catch {
        clearSession();
      } finally {
        setIsLoading(false);
      }
    };

    void boot();
  }, [clearSession]);

  const login = React.useCallback(async (email: string, password: string) => {
    setIsLoading(true);
    setError(null);

    try {
      const response = await apiClient.post<AuthResponse>("/api/auth/login", { email, password });
      persistSession(response.token, response.user);
    } catch (err) {
      if (err instanceof ApiError) {
        handleAuthFailure(err.message);
      } else {
        handleAuthFailure("Unable to log in right now.");
      }
      throw err;
    } finally {
      setIsLoading(false);
    }
  }, [handleAuthFailure, persistSession]);

  const register = React.useCallback(async (username: string, email: string, password: string) => {
    setIsLoading(true);
    setError(null);

    try {
      const response = await apiClient.post<AuthResponse>("/api/auth/register", { username, email, password });
      persistSession(response.token, response.user);
    } catch (err) {
      if (err instanceof ApiError) {
        setError(err.message);
      } else {
        setError("Unable to create account right now.");
      }
      throw err;
    } finally {
      setIsLoading(false);
    }
  }, [persistSession]);

  const logout = React.useCallback(() => {
    clearSession();
    setError(null);
  }, [clearSession]);

  const value = React.useMemo<AuthContextValue>(() => ({
    user,
    token,
    isAuthenticated: Boolean(token && user),
    isLoading,
    error,
    login,
    register,
    logout,
    clearError,
  }), [user, token, isLoading, error, login, register, logout, clearError]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = (): AuthContextValue => {
  const context = React.useContext(AuthContext);

  if (!context) {
    throw new Error("useAuth must be used within AuthProvider.");
  }

  return context;
};
