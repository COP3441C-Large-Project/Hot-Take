import React from "react";
import AuthForm from "../components/AuthForm";

type AuthTab = "login" | "register";

const AuthPage: React.FC = () => {
  const [activeTab, setActiveTab] = React.useState<AuthTab>("login");

  return (
    <div className="min-h-screen bg-white flex">
      <div className="w-[35%] shrink-0 min-h-screen bg-[#E24B4A] flex flex-col justify-between">
        <div className="px-8 pt-12 text-white text-left flex flex-col gap-5">
          <div className="leading-[0.88]">
            <h1 className="text-7xl lowercase">hot</h1>
            <h1 className="text-7xl lowercase whitespace-nowrap">
              take<span className="text-[#EF9F27]">.</span>
            </h1>
          </div>

          <p className="text-sm font-light opacity-85 tracking-wide lowercase">match based on shared interests.</p>
          <p className="text-white/40">────────────────────</p>

          <div className="space-y-3">
            <div>
              <p className="text-[10px] font-light uppercase tracking-[0.2em] opacity-65">No Profiles</p>
              <p className="text-sm font-light opacity-90 whitespace-nowrap">anonymous by default</p>
            </div>
            <div>
              <p className="text-[10px] font-light uppercase tracking-[0.2em] opacity-65">ML Matched</p>
              <p className="text-sm font-light opacity-90 whitespace-nowrap">by shared interests, not looks</p>
            </div>
            <div>
              <p className="text-[10px] font-light uppercase tracking-[0.2em] opacity-65">Low Commitment</p>
              <p className="text-sm font-light opacity-90 whitespace-nowrap">talk when you want. leave when you don't.</p>
            </div>
          </div>
        </div>

        <div className="h-[30%] bg-[#EF9F27] pl-8 pr-4 text-left flex flex-col items-start justify-center gap-3">
          <p className="text-[#4A1B0C]">ALREADY HAVE AN ACCOUNT?</p>
          <button
            type="button"
            onClick={() => setActiveTab("login")}
            className="bg-[#4A1B0C] text-[#EF9F27] py-2 px-16 rounded transition-all duration-150 hover:bg-[#F7C66A] hover:text-[#4A1B0C] hover:shadow-[0_6px_0_#4A1B0C] hover:-translate-y-[1px] active:translate-y-[1px]"
          >
            sign in →
          </button>
          <p className="text-[#4A1B0C] italic text-xs font-light mt-3 opacity-80">hot take · interest-based matchmaking</p>
        </div>
      </div>

      <AuthForm activeTab={activeTab} onTabChange={setActiveTab} />
    </div>
  );
};

export default AuthPage;
