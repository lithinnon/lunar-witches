export default {
  id: "session-title",
  setup: async (api) => {
    // Register native set_session_title tool directly on provider's tool list
    await api.tool.transform((editor) => {
      editor.add({
        name: "set_session_title",
        description:
          "Set a concise, 3 to 8 word summary title for this session. Use on Turn 1 to orient the session in the sidebar.",
        input: {
          type: "object",
          properties: {
            title: {
              type: "string",
              description: "A short, descriptive 3-8 word title summarizing the task."
            }
          },
          required: ["title"],
          additionalProperties: false
        },
        options: { codemode: false },
        execute: async (input, context) => {
          const rawTitle = (input?.title || "").trim();
          if (!rawTitle) {
            return { content: "No title provided." };
          }
          try {
            await api.session.update({
              sessionID: context.sessionID,
              title: rawTitle
            });
            return {
              content: `Session title updated to: "${rawTitle}"`
            };
          } catch (err) {
            return {
              content: `Failed to update session title: ${err?.message || err}`
            };
          }
        }
      });
    });

    // Defensive: Intercept any residual title hook calls to prevent background LLM requests
    api.session.hook("title", async (event) => {
      if (event.result === undefined) {
        event.result = "";
      }
    });
  }
};
