import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Next App",
  description: "project is managed by yarn",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
