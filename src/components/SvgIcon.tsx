'use client';

// src/components/SvgIcon.tsx
// Biblioteka ikon SVG w stylu Lucide (24x24, stroke-based)

import React from 'react';

export type IconName =
    | 'pill'
    | 'search'
    | 'calendar'
    | 'calendar-sync'
    | 'alert-triangle'
    | 'check-circle'
    | 'check'
    | 'x-circle'
    | 'x'
    | 'clipboard'
    | 'clipboard-plus'
    | 'file-text'
    | 'file-pen-line'
    | 'file-x'
    | 'plus'
    | 'plus-circle'
    | 'package'
    | 'clock'
    | 'help-circle'
    | 'settings'
    | 'sun'
    | 'moon'
    | 'loader'
    | 'funnel'
    | 'tags'
    | 'list-tree'
    | 'folder-output'
    | 'folder-input'
    | 'sparkles'
    | 'image-plus'
    | 'trash';

interface SvgIconProps {
    name: IconName;
    size?: number;
    className?: string;
    strokeWidth?: number;
    style?: React.CSSProperties;
}

const iconPaths: Record<IconName, string> = {
    // Pill - pigułka (zastępuje 💊)
    pill: 'M10.5 20.5L3.5 13.5a4.95 4.95 0 1 1 7-7l7 7a4.95 4.95 0 1 1-7 7ZM8.5 8.5l7 7',

    // Search - lupa (zastępuje 🔍)
    search: 'M11 17.25a6.25 6.25 0 1 1 0-12.5 6.25 6.25 0 0 1 0 12.5ZM16 16l5 5',

    // Calendar - kalendarz (zastępuje 📅)
    calendar: 'M19 4H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6a2 2 0 0 0-2-2ZM16 2v4M8 2v4M3 10h18',

    // Alert Triangle - ostrzeżenie (zastępuje ⚠️)
    'alert-triangle': 'M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0ZM12 9v4M12 17h.01',

    // Check Circle - sukces (zastępuje ✅)
    'check-circle': 'M22 11.08V12a10 10 0 1 1-5.93-9.14M22 4L12 14.01l-3-3',

    // Check - ptaszek
    check: 'M20 6L9 17l-5-5',

    // X Circle - błąd (zastępuje ❌)
    'x-circle': 'M12 22a10 10 0 1 1 0-20 10 10 0 0 1 0 20ZM15 9l-6 6M9 9l6 6',

    // X - krzyżyk
    x: 'M18 6L6 18M6 6l12 12',

    // Clipboard - schowek (zastępuje 📋)
    clipboard: 'M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2M9 2h6a1 1 0 0 1 1 1v2a1 1 0 0 1-1 1H9a1 1 0 0 1-1-1V3a1 1 0 0 1 1-1Z',

    // File Text - dokument (zastępuje 📄)
    'file-text': 'M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8ZM14 2v6h6M16 13H8M16 17H8M10 9H8',

    // Plus - plus (zastępuje ➕)
    plus: 'M12 5v14M5 12h14',

    // Plus Circle - plus w kółku
    'plus-circle': 'M12 22a10 10 0 1 1 0-20 10 10 0 0 1 0 20ZM12 8v8M8 12h8',

    // Package - paczka (zastępuje 📦)
    package: 'M16.5 9.4l-9-5.19M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16ZM3.27 6.96L12 12.01l8.73-5.05M12 22.08V12',

    // Clock - zegar (zastępuje ⏰⏳)
    clock: 'M12 22a10 10 0 1 1 0-20 10 10 0 0 1 0 20ZM12 6v6l4 2',

    // Help Circle - pytajnik (zastępuje ❓)
    'help-circle': 'M12 22a10 10 0 1 1 0-20 10 10 0 0 1 0 20ZM9.09 9a3 3 0 0 1 5.83 1c0 2-3 3-3 3M12 17h.01',

    // Settings - zębatka (nowy)
    settings: 'M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2ZM12 15a3 3 0 1 1 0-6 3 3 0 0 1 0 6Z',

    // Sun - słońce (light mode)
    sun: 'M12 17a5 5 0 1 1 0-10 5 5 0 0 1 0 10ZM12 1v2M12 21v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M1 12h2M21 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42',

    // Moon - księżyc (dark mode)
    moon: 'M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79Z',

    // Loader - ładowanie (zastępuje ⏳)
    loader: 'M21 12a9 9 0 1 1-6.219-8.56',

    // Funnel - lejek (dla Filtry)
    funnel: 'M22 3H2l8 9.46V19l4 2v-8.54L22 3Z',

    // Tags - etykiety
    tags: 'M9 5H2v7l6.29 6.29c.94.94 2.48.94 3.42 0l3.58-3.58c.94-.94.94-2.48 0-3.42L9 5ZM6 9.01V9M15 5s2-2 4-2 4 2 4 2v7l-6.29 6.29c-.94.94-2.48.94-3.42 0L15 16',

    // List Tree - lista hierarchiczna
    'list-tree': 'M21 12h-8M21 6h-8M21 18h-8M3 6h2l2 6-2 6H3',

    // Folder Output - eksport folderu
    'folder-output': 'M2 9V5c0-1.1.9-2 2-2h3.93a2 2 0 0 1 1.66.9l.82 1.2a2 2 0 0 0 1.66.9H20a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2v-1M2 13h10M9 9l4 4-4 4',

    // Folder Input - import folderu
    'folder-input': 'M2 9V5c0-1.1.9-2 2-2h3.93a2 2 0 0 1 1.66.9l.82 1.2a2 2 0 0 0 1.66.9H20a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2v-1M12 13H2M5 9l-4 4 4 4',

    // Sparkles - iskry (dla AI/Gemini)
    sparkles: 'M9.937 15.5A2 2 0 0 0 8.5 14.063l-6.135-1.582a.5.5 0 0 1 0-.962L8.5 9.936A2 2 0 0 0 9.937 8.5l1.582-6.135a.5.5 0 0 1 .963 0L14.063 8.5A2 2 0 0 0 15.5 9.937l6.135 1.581a.5.5 0 0 1 0 .964L15.5 14.063a2 2 0 0 0-1.437 1.437l-1.582 6.135a.5.5 0 0 1-.963 0zM20 3v4M22 5h-4M4 17v2M5 18H3',

    // Image Plus - dodaj obraz
    'image-plus': 'M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h7M16 5h6M19 2v6M21 15l-5-5L5 21',

    // Clipboard Plus - schowek z plusem
    'clipboard-plus': 'M9 2h6a1 1 0 0 1 1 1v2a1 1 0 0 1-1 1H9a1 1 0 0 1-1-1V3a1 1 0 0 1 1-1ZM16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2M12 11v6M9 14h6',

    // File Pen Line - edytuj plik
    'file-pen-line': 'M4 22h14a2 2 0 0 0 2-2V7l-5-5H6a2 2 0 0 0-2 2v4M14 2v6h6M2 15h10M5 12l-3 3 3 3',

    // Calendar Sync - synchronizacja dat
    'calendar-sync': 'M11 10H6M11 14H7M19 4H5a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h6M16 2v4M8 2v4M21.121 18.121A3 3 0 1 0 16.5 19.5M21 15v4h-4M16.879 20.879A3 3 0 1 0 21.5 19.5M17 24v-4h4',

    // File X - plik z X (usuń)
    'file-x': 'M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8ZM14 2v6h6M9.5 12.5l5 5M14.5 12.5l-5 5',

    // Trash - kosz
    trash: 'M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2',
};

export function SvgIcon({
    name,
    size = 24,
    className = '',
    strokeWidth = 2,
    style
}: SvgIconProps) {
    const path = iconPaths[name];

    if (!path) {
        console.warn(`SvgIcon: Unknown icon name "${name}"`);
        return null;
    }

    // Special handling for loader animation
    const isLoader = name === 'loader';

    return (
        <svg
            width={size}
            height={size}
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth={strokeWidth}
            strokeLinecap="round"
            strokeLinejoin="round"
            className={`${className} ${isLoader ? 'animate-spin' : ''}`}
            style={style}
            aria-hidden="true"
        >
            <path d={path} />
        </svg>
    );
}

export default SvgIcon;
