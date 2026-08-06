import type { Metadata } from "next";
import { Fraunces, Inter, IBM_Plex_Mono } from "next/font/google";
import "./v3.css";

const fraunces = Fraunces({
  variable: "--font-display",
  subsets: ["latin"],
  axes: ["SOFT", "WONK", "opsz"],
});

const inter = Inter({
  variable: "--font-ui",
  subsets: ["latin"],
});

const plexMono = IBM_Plex_Mono({
  variable: "--font-mono-v3",
  subsets: ["latin"],
  weight: ["400", "500", "600"],
});

export const metadata: Metadata = {
  metadataBase: new URL("https://cue.vyncee.com"),
  title: "Cue — the remote your Mac never had",
  description:
    "Cue turns your iPhone and Apple Watch into a real remote for everything playing on your Mac — Netflix, YouTube Music, Prime, Hotstar, VLC, QuickTime, any tab. Real posters, real titles, over your own Wi-Fi. No cloud, no account. Open source, MIT.",
  openGraph: {
    title: "Cue — the remote your Mac never had",
    description:
      "Control everything playing on your Mac from your iPhone. Real artwork, real titles, real fullscreen — over your own Wi-Fi. No cloud, no account. MIT licensed.",
    type: "website",
    images: ["/og.png"],
  },
};

// Sets the theme attribute before first paint so a stored choice never flashes.
const themeInit = `(function(){try{var t=localStorage.getItem("cue-theme");if(t==="dark"||t==="light"){document.documentElement.setAttribute("data-cue-theme",t)}}catch(e){}})();`;

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body
        className={`cue-v3 ${fraunces.variable} ${inter.variable} ${plexMono.variable}`}
      >
        <script dangerouslySetInnerHTML={{ __html: themeInit }} />
        {children}
      </body>
    </html>
  );
}
