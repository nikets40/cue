"use client";

import { useEffect, useRef } from "react";

type Props = {
  children: React.ReactNode;
  /** entry direction: up (default), l, r, sc */
  dir?: "up" | "l" | "r" | "sc";
  /** stagger children by N ms instead of revealing self */
  stagger?: number;
  className?: string;
  as?: "div" | "section" | "span";
};

export function Reveal({ children, dir = "up", stagger, className = "", as = "div" }: Props) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return;

    const targets: HTMLElement[] = stagger
      ? (Array.from(el.children) as HTMLElement[])
      : [el];

    targets.forEach((t, i) => {
      // elements already in view on mount are never hidden — no flash
      const rect = t.getBoundingClientRect();
      if (rect.top < window.innerHeight * 0.92) return;
      t.classList.add("rv");
      if (dir !== "up") t.classList.add(`rv-${dir}`);
      if (stagger) t.style.setProperty("--rv-delay", `${i * stagger}ms`);
    });

    const io = new IntersectionObserver(
      (entries) => {
        for (const e of entries) {
          if (e.isIntersecting) {
            (e.target as HTMLElement).classList.add("rv-in");
            io.unobserve(e.target);
          }
        }
      },
      { rootMargin: "0px 0px -8% 0px", threshold: 0.05 },
    );
    targets.forEach((t) => t.classList.contains("rv") && io.observe(t));
    return () => io.disconnect();
  }, [dir, stagger]);

  const Tag = as;
  return (
    <Tag ref={ref as React.Ref<never>} className={className}>
      {children}
    </Tag>
  );
}
