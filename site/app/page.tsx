import { Nav } from "../components/nav";
import { Hero } from "../components/hero";
import {
  Sources,
  Artwork,
  Fullscreen,
  Watch,
  Bento,
  Privacy,
  HowItWorks,
  Receipts,
  GetCue,
  FaqSection,
  Footer,
} from "../components/sections";

export default function Page() {
  return (
    <main className="v3-page">
      <Nav />
      <Hero />
      <Sources />
      <Artwork />
      <Fullscreen />
      <Watch />
      <Bento />
      <Privacy />
      <HowItWorks />
      <Receipts />
      <GetCue />
      <FaqSection />
      <Footer />
    </main>
  );
}
