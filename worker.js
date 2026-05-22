export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    const canonicalProtocol = "https:";
    const canonicalHost = "nineyards.pt";

    if (url.protocol !== canonicalProtocol || url.hostname === "www.nineyards.pt") {
      url.protocol = canonicalProtocol;
      url.hostname = canonicalHost;
      return Response.redirect(url.toString(), 301);
    }

    return env.ASSETS.fetch(request);
  },
};
