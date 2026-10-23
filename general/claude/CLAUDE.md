# Personal Standards and Code Guidelines

## 1. Writing and Communication

Explain issues in simple and direct words. Avoid inflated wording and insider jargon.

* **Direct problem-solving:** Lead with the problem in one plain sentence, then the code, then the fix.
* **Visual contrast:** Show a good example next to a bad example instead of describing differences in prose.
* **No jargon:** Avoid technical buzzwords. Use the everyday word instead.
* **State findings directly:** Do not explain the reasoning path. State the conclusion immediately.
* **Zero repetition:** State points exactly once. Do not rephrase.
* **High signal-to-noise:** Include only details that change a decision. Cut everything else.
* **Ban em-dashes:** Do not use em-dashes (`—`) to structure text sentences.
* **Scope:** Applies to code reviews, findings, explanations, chat replies, and documents.
* **Explanations:** Explain complicated things with a picture the reader can see, not a story. Walk through who does what, in order: "Imagine the guest scanning the slip, then the owner claiming it, then the score arriving a minute later." When the flow has more than a few steps, draw it as a small diagram or a step table.
* **No noise**: Cut filler commentary and speculative asides.

## 2. Code Commenting

* **Omit obvious comments:** Do not write boilerplate descriptions or state what a line of code does, ever.
* **Focus on intent:** Explain only the underlying logic, constraints, or "why" behind the code but only if necessary.

## 3. Tone and Vocabulary

* **Professional tone:** Maintain an internationally accessible communication style.

## 4. Code Review Comments

How inline comments on a pull request read.

* **Shape:** One to three short sentences. Say what is wrong and what it causes in terms the reader sees (what the user gets, what breaks), not raw internal values they have to decode. Then either ask for the fix ("Could `byIds` take the viewer instead?") or state the gap plainly ("The 400 for a short code isn't documented:"). Then the code.
* **Show the fix:** Add code whenever possible, limited to the lines that change. Use a ` ```suggestion ` block when it replaces the commented lines exactly. Use a language block (` ```ts `) when the fix lives elsewhere or is a sketch.
* **Point to precedent:** Name existing code that already does it right: "like `UserCacheModule` does for `USER_CACHE`".
* **Labels:** No severity tags, bold titles or headings. Start with `Edge case:` for a rare path and `Nit:` for something optional. Use no label otherwise.
* **Tone:** Friendly and direct. No greetings, thanks, praise, "I think", "please", hedging or sign-off. No attribution.
* **Code names:** Put every identifier, file, status and value in backticks.
* **One review, no summary:** Post all comments as a single review with an empty body.
* **Placement:** Anchor each comment on the lines it is about, inside the diff. When the problem sits outside the diff, anchor on the nearest related changed line and name the real `file:line`.

Bad (label, hedging, filler):
> High: Potential issue with expired tokens. I think there might potentially be an issue where this guard answers as a visitor, so they get CLAIMED instead of YOURS. Please consider handling this. Thanks!

Bad ("CLAIMED instead of YOURS" means nothing unless you know the enum):
> Edge case: when the owner's token has expired, this guard answers as a visitor, so they get CLAIMED instead of YOURS. With no 401, the app never refreshes. Could a token that is sent but invalid answer 401 here?

Good (the cause, what the user sees, why it stays broken, the fix as a question):
> Edge case: an expired token gets treated as a visitor here, so the owner sees their own item as claimed by someone else. With no 401, the app never refreshes. Could a sent-but-invalid token return 401?

<!-- CODEGRAPH_START -->
## CodeGraph

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

* **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow. Name a file or symbol in the query to read its current line-numbered source. If it's listed but deferred, load it by name via tool search.
* **Shell** (always works): `codegraph explore "<symbol names or question>"` prints the same output.

If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.
<!-- CODEGRAPH_END -->
