import React, { useState } from "react";

type AuthTab = "login" | "register";

interface AuthFormProps {
    activeTab: AuthTab;
    onTabChange: (tab: AuthTab) => void;
}

const AuthForm: React.FC<AuthFormProps> = ({ activeTab, onTabChange }) => {
    return (
        <div
            className="flex-1 min-h-screen flex items-start justify-center bg-white px-8 pt-20"
            style={{
                backgroundImage:
                    "linear-gradient(to right, rgba(0, 0, 0, 0.06) 1px, transparent 1px), linear-gradient(to bottom, rgba(0, 0, 0, 0.06) 1px, transparent 1px)",
                backgroundSize: "60px 60px",
            }}
        >
            <div className="flex min-h-[calc(100vh-5rem)] w-full max-w-md flex-col">
                <h2 className="mb-8 text-3xl font-normal lowercase text-black">
                    {activeTab === "login" ? "sign in" : "create account"}
                </h2>

                <div className="grid grid-cols-2 gap-2 rounded-xl bg-[#F1EFE8] p-1">
                    <button
                        type="button"
                        onClick={() => onTabChange("login")}
                        className={`rounded-lg px-4 py-2 text-sm font-normal lowercase transition ${
                            activeTab === "login" ? "bg-white text-black" : "bg-[#F1EFE8] text-[#888780]"
                        }`}
                    >
                        sign in
                    </button>
                    <button
                        type="button"
                        onClick={() => onTabChange("register")}
                        className={`rounded-lg px-4 py-2 text-sm font-normal lowercase transition ${
                            activeTab === "register" ? "bg-white text-black" : "bg-[#F1EFE8] text-[#888780]"
                        }`}
                    >
                        register
                    </button>
                </div>

                <div className="mt-10 space-y-4">
                    <div>
                        <label className="mb-2 block text-[10px] font-light uppercase tracking-[0.2em] text-[#888780]">USERNAME</label>
                        <input
                            type="text"
                            className="w-full rounded-lg border border-[#D3D1C7] bg-[#F7F7F5] px-4 py-3 text-[#888780] outline-none transition placeholder:text-[#888780] focus:border-[#EF9F27]"
                        />
                    </div>

                    {activeTab === "register" && (
                        <div>
                            <label className="mb-2 block text-[10px] font-light uppercase tracking-[0.2em] text-[#888780]">EMAIL</label>
                            <input
                                type="email"
                                placeholder="you@example.com"
                                className="w-full rounded-lg border border-[#D3D1C7] bg-[#F7F7F5] px-4 py-3 text-[#888780] outline-none transition placeholder:text-[#888780] focus:border-[#EF9F27]"
                            />
                        </div>
                    )}

                    <div>
                        <label className="mb-2 block text-[10px] font-light uppercase tracking-[0.2em] text-[#888780]">PASSWORD</label>
                        <input
                            type="password"
                            className="w-full rounded-lg border border-[#D3D1C7] bg-[#F7F7F5] px-4 py-3 text-[#888780] outline-none transition placeholder:text-[#888780] focus:border-[#EF9F27]"
                        />
                    </div>

                    {activeTab === "register" && (
                        <div>
                            <label className="mb-2 block text-[10px] font-light uppercase tracking-[0.2em] text-[#888780]">CONFIRM PASSWORD</label>
                            <input
                                type="password"
                                className="w-full rounded-lg border border-[#D3D1C7] bg-[#F7F7F5] px-4 py-3 text-[#888780] outline-none transition placeholder:text-[#888780] focus:border-[#EF9F27]"
                            />
                        </div>
                    )}

                    <button
                        type="button"
                        className="mt-4 w-full rounded-full bg-[#E24B4A] px-4 py-3 text-sm font-normal lowercase text-white transition hover:bg-[#E24B4A] hover:text-white hover:shadow-[0_6px_0_#4A1B0C] active:bg-white active:text-black active:translate-y-[1px]"
                    >
                        {activeTab === "login" ? "sign in" : "create account"}
                    </button>

                    <p className="mt-auto pt-8 text-center text-xs italic lowercase text-[#888780]">
                        your identity is never shared with matches
                    </p>
                </div>
            </div>
        </div>
    );
};

export default AuthForm;