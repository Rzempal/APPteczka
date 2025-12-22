// Animated Header Component - React/Next.js with Tailwind CSS
// Features: scroll-triggered collapse, expandable hamburger, mobile slide-in menu
"use client";

import Link from "next/link";
import Image from "next/image";
import { useState, useEffect } from "react";
import { cn } from "@/lib/utils"; // or use clsx/classnames

export function Header() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [isScrolled, setIsScrolled] = useState(false);
  const [isExpanded, setIsExpanded] = useState(false);

  // Scroll detection with passive listener for performance
  useEffect(() => {
    const handleScroll = () => {
      const scrolled = window.scrollY > 50;
      setIsScrolled(scrolled);
      // Reset expanded state when user scrolls back to top
      if (!scrolled) {
        setIsExpanded(false);
      }
    };

    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  // Show full nav when: not scrolled OR expanded OR mobile menu open
  const showFullNav = !isScrolled || isExpanded || mobileMenuOpen;

  return (
    <>
      <header className="fixed top-0 left-0 right-0 z-50 bg-white/90 backdrop-blur-md border-b border-gray-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex h-20 items-center justify-between">
            {/* Logo Section */}
            <Link href="/" className="flex items-center gap-3">
              <Image
                src="/logo.png"
                alt="Logo"
                width={40}
                height={40}
                className="h-10 w-auto flex-shrink-0"
              />
              {/* Text - slides out left and fades when scrolled */}
              <span
                className={cn(
                  "text-xl font-semibold tracking-tight transition-all duration-500 ease-out whitespace-nowrap overflow-hidden",
                  showFullNav
                    ? "max-w-[200px] opacity-100 translate-x-0"
                    : "max-w-0 opacity-0 -translate-x-4"
                )}
              >
                Brand Name<span className="text-red-500">.</span>
              </span>
            </Link>

            {/* Desktop Navigation - slides out right and fades when scrolled */}
            <div className="hidden lg:flex items-center gap-10">
              <nav
                className={cn(
                  "flex items-center gap-10 transition-all duration-500 ease-out overflow-hidden",
                  showFullNav
                    ? "max-w-[600px] opacity-100 translate-x-0"
                    : "max-w-0 opacity-0 translate-x-8"
                )}
              >
                <Link href="/products" className="nav-link whitespace-nowrap">
                  Products
                </Link>
                <Link href="/about" className="nav-link whitespace-nowrap">
                  About
                </Link>
                <Link href="/blog" className="nav-link whitespace-nowrap">
                  Blog
                </Link>
                <Link href="/contact" className="nav-link whitespace-nowrap">
                  Contact
                </Link>
              </nav>

              {/* CTA Button - slides out right and fades when scrolled */}
              <div
                className={cn(
                  "transition-all duration-500 ease-out overflow-hidden",
                  showFullNav
                    ? "max-w-[200px] opacity-100 translate-x-0"
                    : "max-w-0 opacity-0 translate-x-8"
                )}
              >
                <Link
                  href="/shop"
                  className="inline-flex items-center gap-2 px-6 py-3 bg-gray-900 text-white font-medium text-sm uppercase tracking-wide hover:bg-red-500 transition-colors whitespace-nowrap"
                >
                  Shop Now
                  <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                    <path
                      d="M3 8H13M13 8L9 4M13 8L9 12"
                      stroke="currentColor"
                      strokeWidth="1.5"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    />
                  </svg>
                </Link>
              </div>

              {/* Desktop Hamburger - appears when scrolled */}
              <button
                type="button"
                className={cn(
                  "inline-flex items-center justify-center p-2 text-gray-900 hover:text-red-500 transition-all duration-500",
                  isScrolled
                    ? "opacity-100 translate-x-0 pointer-events-auto"
                    : "opacity-0 translate-x-4 pointer-events-none absolute"
                )}
                onClick={() => setIsExpanded(!isExpanded)}
                aria-expanded={isExpanded}
                aria-label={isExpanded ? "Collapse menu" : "Expand menu"}
              >
                {isExpanded ? (
                  <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                ) : (
                  <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5" />
                  </svg>
                )}
              </button>
            </div>

            {/* Mobile Menu Button */}
            <button
              type="button"
              className="lg:hidden inline-flex items-center justify-center p-2 text-gray-900 hover:text-red-500 transition-colors"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              aria-expanded={mobileMenuOpen}
              aria-label={mobileMenuOpen ? "Close menu" : "Open menu"}
            >
              {mobileMenuOpen ? (
                <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
                </svg>
              ) : (
                <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5" />
                </svg>
              )}
            </button>
          </div>
        </div>
      </header>

      {/* Mobile Navigation Panel */}
      {mobileMenuOpen && (
        <div className="lg:hidden fixed top-20 left-0 right-0 bottom-0 z-[100]">
          <div className="mobile-menu-panel h-full w-full bg-white flex flex-col justify-center items-center px-8">
            {/* Navigation Links - Staggered from right */}
            <nav className="flex flex-col items-center gap-6 mb-12 w-full">
              <Link
                href="/products"
                className="mobile-nav-link text-3xl font-bold tracking-tight text-gray-900 hover:text-red-500 transition-colors"
                onClick={() => setMobileMenuOpen(false)}
              >
                Products
              </Link>
              <Link
                href="/about"
                className="mobile-nav-link text-3xl font-bold tracking-tight text-gray-900 hover:text-red-500 transition-colors"
                onClick={() => setMobileMenuOpen(false)}
              >
                About
              </Link>
              <Link
                href="/blog"
                className="mobile-nav-link text-3xl font-bold tracking-tight text-gray-900 hover:text-red-500 transition-colors"
                onClick={() => setMobileMenuOpen(false)}
              >
                Blog
              </Link>
              <Link
                href="/contact"
                className="mobile-nav-link text-3xl font-bold tracking-tight text-gray-900 hover:text-red-500 transition-colors"
                onClick={() => setMobileMenuOpen(false)}
              >
                Contact
              </Link>
            </nav>

            {/* CTA Buttons - Staggered from bottom */}
            <div className="flex flex-col gap-4 w-full max-w-sm">
              <Link
                href="/shop"
                className="mobile-cta flex items-center justify-center gap-3 px-8 py-4 bg-gray-900 text-white font-medium uppercase tracking-wide text-sm hover:bg-red-500 transition-colors w-full"
                onClick={() => setMobileMenuOpen(false)}
              >
                Shop Now
              </Link>
              <Link
                href="/contact"
                className="mobile-cta flex items-center justify-center gap-3 px-8 py-4 border-2 border-gray-900 bg-transparent text-gray-900 font-medium uppercase tracking-wide text-sm hover:bg-gray-900 hover:text-white transition-colors w-full"
                onClick={() => setMobileMenuOpen(false)}
              >
                Get in Touch
              </Link>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
