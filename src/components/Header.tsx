"use client";

import Link from "next/link";
import { useState, useEffect, useCallback } from "react";

const navItems = [
    { href: "/", label: "Apteczka", icon: "💊" },
    { href: "/dodaj", label: "Dodaj leki", icon: "➕" },
    { href: "/konsultacja", label: "Konsultacja AI", icon: "🩺" },
    { href: "/backup", label: "Kopia zapasowa", icon: "💾" },
];

export function Header() {
    const [iconsVisible, setIconsVisible] = useState(true);
    const [isAnimating, setIsAnimating] = useState(false);
    const [lastScrollY, setLastScrollY] = useState(0);

    // Handle scroll - toggle hamburger menu only
    const handleScroll = useCallback(() => {
        const currentScrollY = window.scrollY;
        const scrollDelta = currentScrollY - lastScrollY;

        // Scroll down - collapse menu (when past threshold)
        if (currentScrollY > 50 && scrollDelta > 15 && iconsVisible && !isAnimating) {
            setIsAnimating(true);
            setTimeout(() => {
                setIconsVisible(false);
                setIsAnimating(false);
            }, 200);
        }

        // Scroll to top - expand menu (only when at the very top)
        if (currentScrollY <= 5 && !iconsVisible && !isAnimating) {
            setIconsVisible(true);
        }

        setLastScrollY(currentScrollY);
    }, [lastScrollY, iconsVisible, isAnimating]);

    useEffect(() => {
        window.addEventListener('scroll', handleScroll, { passive: true });
        return () => window.removeEventListener('scroll', handleScroll);
    }, [handleScroll]);

    // Toggle icons visibility with animation
    const toggleIcons = () => {
        if (iconsVisible) {
            // Hide icons with popOut
            setIsAnimating(true);
            setTimeout(() => {
                setIconsVisible(false);
                setIsAnimating(false);
            }, 200);
        } else {
            // Show icons with popIn
            setIconsVisible(true);
        }
    };

    // Handle link click on mobile - close menu
    const handleMobileLinkClick = () => {
        // Close menu after click on mobile
        if (window.innerWidth < 640) {
            setIsAnimating(true);
            setTimeout(() => {
                setIconsVisible(false);
                setIsAnimating(false);
            }, 200);
        }
    };

    return (
        <header className="sticky top-0 z-50">
            <nav className="mx-auto max-w-7xl px-4 py-4 sm:px-6">
                {/* Main navbar container */}
                <div className="neu-flat p-4 animate-fadeInUp">
                    {/* Top row: Logo + icons + hamburger */}
                    <div className="flex items-center justify-between">
                        {/* Logo Section */}
                        <Link href="/" className="flex items-center gap-2 group">
                            <span className="text-2xl group-hover:scale-110 transition-transform">
                                💊
                            </span>
                            <span
                                className={`text-xl font-bold transition-all duration-300 overflow-hidden ${iconsVisible
                                    ? 'max-w-[120px] opacity-100 translate-x-0'
                                    : 'max-w-0 opacity-0 -translate-x-4'
                                    }`}
                                style={{ color: "var(--color-accent)" }}
                            >
                                APPteczka
                            </span>
                        </Link>

                        {/* Right side: icons + hamburger */}
                        <div className="flex items-center gap-2 py-2">
                            {/* Desktop inline icons - shown when iconsVisible */}
                            {(iconsVisible || isAnimating) && (
                                <div className="hidden sm:flex items-center gap-2">
                                    {navItems.map((item, index) => (
                                        <Link
                                            key={item.href}
                                            href={item.href}
                                            className={`neu-tag whitespace-nowrap ${isAnimating ? "animate-buttonPress" : "animate-popIn"}`}
                                            style={{ animationDelay: `${index * 0.05}s` }}
                                        >
                                            <span>{item.icon}</span>
                                            <span className="ml-1">{item.label}</span>
                                        </Link>
                                    ))}
                                </div>
                            )}

                            {/* Hamburger button - always visible, pressed effect when icons visible */}
                            <button
                                type="button"
                                className={`inline-flex items-center justify-center p-2 neu-tag transition-all duration-300 ${iconsVisible ? "active" : ""
                                    }`}
                                onClick={toggleIcons}
                                aria-expanded={iconsVisible}
                                aria-label={iconsVisible ? "Ukryj menu" : "Pokaż menu"}
                            >
                                <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
                                    <path strokeLinecap="round" strokeLinejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5" />
                                </svg>
                            </button>
                        </div>
                    </div>

                    {/* Mobile Navigation - dropdown inside container */}
                    {(iconsVisible || isAnimating) && (
                        <div
                            className="sm:hidden overflow-hidden transition-all duration-300 mt-4 pt-4 border-t border-[var(--shadow-dark)]"
                            style={{ transitionTimingFunction: "var(--navbar-easing)" }}
                        >
                            <div className="flex flex-wrap justify-center gap-3 py-1">
                                {navItems.map((item, index) => (
                                    <Link
                                        key={item.href}
                                        href={item.href}
                                        className={`neu-tag ${isAnimating ? "animate-buttonPress" : "animate-popIn"}`}
                                        style={{ animationDelay: `${index * 0.06}s` }}
                                        onClick={handleMobileLinkClick}
                                    >
                                        <span>{item.icon}</span>
                                        <span className="ml-1">{item.label}</span>
                                    </Link>
                                ))}
                            </div>
                        </div>
                    )}
                </div>
            </nav>
        </header>
    );
}
