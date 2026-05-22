const HTML = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="robots" content="noindex,nofollow">
  <title>nineyards — Under Maintenance</title>
  <style>
    @font-face {
      font-family: Clashdisplay;
      src: url("/fonts/ClashDisplay-Semibold.otf") format("opentype");
      font-weight: 600;
    }
    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    html, body {
      height: 100%;
      background: #0d0d0d;
      color: #fff;
      font-family: Clashdisplay, Arial, sans-serif;
      display: flex;
      align-items: center;
      justify-content: center;
      text-align: center;
    }
    .wrap { padding: 2rem; max-width: 560px; }
    .logo { font-size: 1.25rem; font-weight: 600; letter-spacing: 0.08em; margin-bottom: 3rem; opacity: 0.5; }
    h1 { font-size: clamp(2rem, 8vw, 4rem); font-weight: 600; line-height: 100%; margin-bottom: 1.5rem; }
    p { font-family: "Inter Tight", Arial, sans-serif; font-size: 1rem; line-height: 160%; color: #ffffff99; }
  </style>
</head>
<body>
  <div class="wrap">
    <div class="logo">nineyards</div>
    <h1>Under Maintenance</h1>
    <p>We're making some updates and will be back shortly.<br>Thank you for your patience.</p>
  </div>
</body>
</html>`;

export default {
  fetch() {
    return new Response(HTML, {
      status: 503,
      headers: {
        "Content-Type": "text/html; charset=utf-8",
        "Retry-After": "3600",
      },
    });
  },
};
