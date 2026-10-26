const titledSessions = new Set();

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
          const sid = context.sessionID;
          if (titledSessions.has(sid)) {
            return {
              content: "Session title is already set. Do not call set_session_title again in this session. Proceed immediately with your response."
            };
          }
          const rawTitle = (input?.title || "").trim();
          if (!rawTitle) {
            return { content: "No title provided." };
          }
          try {
            await api.session.update({
              sessionID: sid,
              title: rawTitle
            });
            titledSessions.add(sid);
            return {
              content: `Session title successfully set to: "${rawTitle}". Do not call set_session_title again in this session.`
            };
          } catch (err) {
            return {
              content: `Failed to update session title: ${err?.message || err}`
            };
          }
        }
      });
    });
  }
};
