---
title: "When Event Sourcing clicked for me"
url: "/2025/11/23/when-es-clicked"
timestamp: "2025-11-23 18:30:00 +0100"
---
Recently I was giving [a talk about the Decider pattern](https://luma.com/se3qppbl), and I was asked when Event Sourcing clicked for me. I'm too old to remember *when*, but I still remember *what* it was.

[Let me quote myself](https://www.monterail.com/blog/introduction-to-domain-events):

> My personal greatest benefit of events is the influence on the way I think about designing the system. **The moment when you have to name the fact that actually happens opens a magic box in your head** that unveils edge cases, impacts on other parts of the system, or unknowns that you have to ask the client. It really changes the way you think and communicates with others. It shapes your language.

I still remember this mind-blowing effect when I realized how powerful this simple concept is. That instead of overriding a row in the database, I have to name **in business terms** what just happened (so no to [CRUD-sourcing](https://codeopinion.com/crud-sourcing-is-why-your-event-streams-are-bloated/)).

If you think that naming is hard, you will quickly realize how painfully hard it is to name every operation in the system. And that often you simply don't know why something happens. Or what consequences such actions should have. But thanks to this pain, you will quickly become a person who is not afraid to ask "dumb" questions or start thinking a few steps ahead. You will start noticing when duplication is a pattern to DRY or when it is just similarity that should stay duplicated. That leads to simpler solutions and maintainable systems that are more flexible and easier to change.

It's a win for business and for you.

<small>Of course, just the fact you use events does not mean you have to use event sourcing. However, event sourcing pushes you for real business naming, so it a has bigger impact.</small>
