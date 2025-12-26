"use client";

import Link from "next/link";
import Image from "next/image";
import { useState, useEffect, useCallback } from "react";
import { SvgIcon } from "./SvgIcon";

type NavItem = {
    href: string;
    label: string;
    icon: string;
    isImage?: boolean;
    isSvg?: boolean;
    svgName?: "plus" | "settings" | "sun" | "moon";
};

const navItems: NavItem[] = [
    { href: "/", label: "Apteczka", icon: "/icons/apteczka.png", isImage: true },
    { href: "/dodaj", label: "Dodaj leki", icon: "plus", isSvg: true, svgName: "plus" },
    { href: "/backup", label: "Kopia zapasowa", icon: "/icons/backup.png", isImage: true },
];

export function Header() {
    const [iconsVisible, setIconsVisible] = useState(true);
    const [isAnimating, setIsAnimating] = useState(false);
    const [lastScrollY, setLastScrollY] = useState(0);
    const [settingsOpen, setSettingsOpen] = useState(false);
    const [isDarkMode, setIsDarkMode] = useState(false);

    // Initialize theme from localStorage on mount
    useEffect(() => {
        const savedTheme = localStorage.getItem('theme');
        const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;

        if (savedTheme === 'dark' || (!savedTheme && prefersDark)) {
            setIsDarkMode(true);
            document.documentElement.setAttribute('data-theme', 'dark');
        } else if (savedTheme === 'light') {
            setIsDarkMode(false);
            document.documentElement.setAttribute('data-theme', 'light');
        }
    }, []);

    // Toggle theme
    const toggleTheme = () => {
        const newTheme = isDarkMode ? 'light' : 'dark';
        setIsDarkMode(!isDarkMode);
        document.documentElement.setAttribute('data-theme', newTheme);
        localStorage.setItem('theme', newTheme);
    };

    // Close settings when clicking outside
    useEffect(() => {
        const handleClickOutside = (e: MouseEvent) => {
            const target = e.target as HTMLElement;
            if (!target.closest('.settings-wrapper')) {
                setSettingsOpen(false);
            }
        };

        if (settingsOpen) {
            document.addEventListener('click', handleClickOutside);
            return () => document.removeEventListener('click', handleClickOutside);
        }
    }, [settingsOpen]);

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
                    {/* Top row: Logo + icons + settings + hamburger */}
                    <div className="flex items-center justify-between min-h-[40px]">
                        {/* Logo Section */}
                        <Link href="/" className="flex items-center gap-2 group h-8">
                            <Image
                                src="/favicon.png"
                                alt="Pudełko na leki logo"
                                width={32}
                                height={32}
                                className="shrink-0 group-hover:scale-110 transition-transform"
                            />
                            <span
                                className={`text-xl font-bold transition-all duration-300 overflow-hidden whitespace-nowrap ${iconsVisible
                                    ? 'max-w-[160px] opacity-100 translate-x-0'
                                    : 'max-w-0 opacity-0 -translate-x-4'
                                    }`}
                                style={{ color: "var(--color-accent)" }}
                            >
                                Pudełko na leki
                            </span>
                        </Link>

                        {/* Right side: icons + settings + hamburger */}
                        <div className="flex items-center gap-2">
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
                                            {item.isImage ? (
                                                <Image src={item.icon} alt={item.label} width={20} height={20} />
                                            ) : item.isSvg && item.svgName ? (
                                                <SvgIcon name={item.svgName} size={18} />
                                            ) : (
                                                <span>{item.icon}</span>
                                            )}
                                            <span className="ml-1">{item.label}</span>
                                        </Link>
                                    ))}
                                </div>
                            )}

                            {/* Settings button - between nav items and hamburger */}
                            <div className="settings-wrapper relative">
                                <button
                                    type="button"
                                    className={`inline-flex items-center justify-center p-2 neu-tag transition-all duration-300 ${settingsOpen ? "active" : ""}`}
                                    onClick={(e) => {
                                        e.stopPropagation();
                                        setSettingsOpen(!settingsOpen);
                                    }}
                                    aria-expanded={settingsOpen}
                                    aria-label="Ustawienia"
                                >
                                    <SvgIcon name="settings" size={22} />
                                </button>

                                {/* Settings Dropdown */}
                                <div className={`settings-dropdown ${settingsOpen ? 'show' : ''}`}>
                                    <div className="settings-item">
                                        <span>Tryb ciemny</span>
                                        <div
                                            className="theme-toggle"
                                            onClick={toggleTheme}
                                            role="button"
                                            aria-label="Przełącz motyw"
                                        >
                                            <div className="theme-toggle-thumb">
                                                <SvgIcon name={isDarkMode ? "moon" : "sun"} size={14} />
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            </div>

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
                                        {item.isImage ? (
                                            <Image src={item.icon} alt={item.label} width={20} height={20} />
                                        ) : item.isSvg && item.svgName ? (
                                            <SvgIcon name={item.svgName} size={18} />
                                        ) : (
                                            <span>{item.icon}</span>
                                        )}
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
