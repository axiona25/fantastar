"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useAuth } from "@/hooks/useAuth";
import { setOnUnauthorized } from "@/services/apiClient";
import { Button } from "@/components/ui/button";
import { useEffect } from "react";

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const router = useRouter();
  const { user, logout, fetchMe } = useAuth(true);

  useEffect(() => {
    setOnUnauthorized(() => router.push("/login"));
    return () => setOnUnauthorized(null);
  }, [router]);

  const isAuthPage = pathname === "/login" || pathname === "/register";

  useEffect(() => {
    if (isAuthPage) return;
    const token = typeof window !== "undefined" ? localStorage.getItem("access_token") : null;
    if (!token && !user) router.push("/login");
  }, [isAuthPage, user, router]);

  return (
    <div className="min-h-screen flex flex-col">
      <header className="border-b border-zinc-200 dark:border-zinc-800">
        <nav className="container mx-auto flex items-center justify-between px-4 py-3">
          <div className="flex gap-4">
            <Link href="/" className="font-medium hover:underline">FANTASTAR</Link>
            {user && (
              <>
                <Link href="/live" className={pathname === "/live" ? "underline" : ""}>Live</Link>
                <Link href="/standings" className={pathname === "/standings" ? "underline" : ""}>Classifiche</Link>
                <Link href="/news" className={pathname === "/news" ? "underline" : ""}>News</Link>
                <Link href="/team" className={pathname.startsWith("/team") ? "underline" : ""}>Squadra</Link>
              </>
            )}
          </div>
          <div className="flex items-center gap-2">
            {user ? (
              <>
                <Link href="/settings/notifications" className="text-sm text-zinc-500 hover:underline">Notifiche</Link>
                <span className="text-sm text-zinc-500">{user.username}</span>
                <Button variant="ghost" onClick={() => { logout(); router.push("/login"); }}>Esci</Button>
              </>
            ) : (
              !isAuthPage && (
                <Link href="/login"><Button variant="outline">Accedi</Button></Link>
              )
            )}
          </div>
        </nav>
      </header>
      <main className="flex-1 container mx-auto p-4">{children}</main>
    </div>
  );
}
