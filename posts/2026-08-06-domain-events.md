---
title: "Introduction to Domain Events"
url: "/2026/08/06/domain-events"
timestamp: "2026-08-06 18:40:00 +0200"
---
_Originally published at [monterail.com](https://monterail.com) blog_

Recently we made an [introduction to the Rails Event Store](https://www.monterail.com/blog/introduction-to-rails-event-store) but to get fully into the topic there are dozens of ideas to learn about, so we won’t stop there. Today I would like to tackle the simplest problem in the stack - Domain Events.

## What is a Domain Event?

> **Domain Event:** a data structure representing one domain change

[blog.sapiensworks.com](http://blog.sapiensworks.com/post/2015/05/25/DDD-Concepts-As-One-Liners)

> An event is something that has happened in the past

[Domain Events Design Implementation](https://docs.microsoft.com/en-us/dotnet/standard/microservices-architecture/microservice-ddd-cqrs-patterns/domain-events-design-implementation)

You can find a lot of definitions on the web and based on them we can conclude that event is:

* a fact
* an immutable struct
* a mutation

Let’s discuss each one in short.

## Event is a Fact

An event describes something that happened in the past. It’s a fact and you cannot argue with it. When a new event comes in you don’t have to validate it - it’s rather a contrary, you have to accept it fully, no matter if you’re ready for the truth or not. Because an event represents the truth. You cannot erase it and if you don’t like the fact you can either ignore the event or raise a new one that will change the current state into the desired one.

## Event is an Immutable Struct

Technically speaking, an event is as simple, as struct is. To put it simply it’s a named bunch of data. In an extreme case, it might be just a name, without any data, but in most cases, an event will carry on few ids, changed values and that's it. As you can see, an event is also a very simple struct.

A struct means no logic, no additional methods, just plain data, and getters.

Cause the event is a fact, you cannot change it, so there are only getters and no setters.

## Event is a Mutation

An event represents change. Something was _updated_, _moved_, _increased_, _turned off_, _switched_, _removed_, _selected_, _assigned_ - the vocabulary is full of verbs that can describe the change. If you struggle to find a proper name you can also ask for help on a [thesaurus](https://www.thesaurus.com/).

Now, when we already covered what is an event, let’s discuss a few issues that you might encounter when you decide to start implementing them.

## Common Issues With Implementing Domain Events

### Naming

> There are only two hard things in Computer Science: cache invalidation and naming things.

- Phil Karlton

Thankfully, there is a well-defined convention for naming events - noun + verb in the past tense. I like to follow a [recommendation from Mathias Verraes](https://verraes.net/2014/11/domain-events/):

> I recommend using natural language and making small sentences, such as “Stock was depleted”, instead of newspaper-style shortcuts such as “Depleted stock”. In my experience, this greatly improves communication and understanding.

so it’s a noun + was + verb for me but it’s a cosmetic detail and matter of personal preference. Few examples for event names, to make it more clear:

* `ItemWasAdded`
* `ProductWasOrdered`
* `InvoiceEmailWasGenerated`
* `ToggleWasSwitchedOff`
* `CompanyWasArchived`

The best place to find proper nouns and verbs is in the business you are modeling. Such vocabulary creates something called [ubiquitous language](https://martinfowler.com/bliki/UbiquitousLanguage.html), and it’s a topic that deserves its own series of posts.

### Granularity

One of the most tricky issues that you might have at the beginning of an adventure with events is when it comes to deciding how big or small your event should be.

Should I be more explicit and raise small events like `FirstNameWasChanged` or `EmailWasUpdated`? This approach allows us to be more flexible - you can create handlers that will react only to a piece of very specific information that is needed in the process. On the other hand, you will probably end up with much more code to write, and - in case of a lot of changes in a single request - it could mean a lot of unnecessary hits to the database.

```ruby
class OnFirstNameWasChanged
  # @param [Events::FirstNameWasChanged]
  def call(event)
    User.find(event.data.user_id).update!(event.data.first_name)
  end
end
```

An obvious alternative is to go big, like `ProfileWasChanged`, so you can handle a lot of things in one hit. The problem is, that now your handlers probably need some routing, they have to check what kind of data the event provides. You might have to deal with `nulls` and decide if `null` means “nothing changed” or “clean the value” but then you will have to send redundant data that haven’t changed but you don’t want to remove them.

```ruby
class OnProfileWasChanged
  # @param [Events::ProfileWasChanged]
  def call(event)
    user = User.find(event.data.user_id)

    # nil means "nothing changed"
    user.first_name = event.data.first_name if event.data.first_name

    # nil means "clean the value"
    # so we have to send the value no matter if it changed or not
    user.last_name = event.data.last_name

    user.save!
  end
end
```

What’s worse, big events are brittle to refactorings and changes to the event schema, so you have to learn how to make extra steps and how to deal with such cases (btw - there is a [great book](https://leanpub.com/esversioning) that covers these issues).

So far I have three simple heuristics that help me decide which way to go:

* significance - how significant is a specific change? Does it have any impact? Changing an email might require a confirmation, it is a very important piece of data from the security point of view so it would make sense to keep it in an explicit, small event
* subscribers - you can adjust to the needs of your subscribers and split data e.g. into a few small and one or two bigger events that will suit their needs
* mutuality - keeping first and last name makes sense as well as any other data that describes an entity so it might make sense to keep them together in a bigger event


You can read more e.g. on the [sapiens works](http://blog.sapiensworks.com/post/2014/03/27/Domain-Event-Design-Principles.aspx) blog or listen to a [better software design](https://bettersoftwaredesign.pl/podcast/o-nazewnictwie-eventow/) podcast (in Polish).

### Data

Your events should carry on some data, i.e.:

* every related aggregate id
* timestamp
* the version number of a structure
* data that has changed

The timestamp is a no-brainer - it’s good to know when the event happened and libraries like [Rails Event Store](https://railseventstore.org) keep you covered here out of the box. Although timestamp is not a domain related detail, it might be a good idea to keep it separated, e.g. as metadata, along with a request IP address and `user_id` who triggered the action.

Changed data probably also don’t need a separate explanation - you want to track what exactly happened and changed so you have to put details into the event, like a new name, updated price, etc.

Let’s imagine that we have three entities - `Product`, `Cart` and `Buyer`. When you add a product to the cart it would be obvious to add `product_id` and `cart_id` to the related event. But should you also add `buyer_id`? Since this introduces a little redundancy - `buyer_id` might be tracked thanks to `cart_id` - you might be tempted to save some space but I would argue against such optimization. Keeping all related aggregate ids in an event will often simplify your handlers (no need to query for the buyer if you need to pass a `buyer_id` in further actions) but more importantly - it would give you more flexibility for filtering streams, e.g. when you want to process all events related to the buyer.

Last but not least, we have to remember that the only constant thing in the world is change. And so, your requirements may change, your understanding of the domain may change or you simply may want to introduce the change to fix a bug. And such change might require changing the struct of an event which is not as simple as it might sound - as you remember events are immutable facts and we cannot update the history. There are different strategies how to deal with this problem (I would like to recommend Greg Young’s book again) but most of them are based on keeping the version number of a struct in the event. The version might be hardcoded in the event name, e.g. SomethingImportantHappenedV1 but personally, I prefer to keep it in the event metadata.

### Weak vs Strict Schema

Rails Event Store by default provides schema-less events. Such event might be implemented with a single line, e.g. `FooHappened = Class.new(RailsEventStore::Event)`. This approach is great for learning and experimentation purposes but we don’t recommend it for production. Lack of schema means your events will accept any hash you will provide and that will kick your butt with unexpected `nil`, typos, overlooked fields, etc [in the worst possible moment](https://en.wikipedia.org/wiki/Murphy%27s_law).

The sky is the limit when it comes to implementing a format for a strict schema for events but probably the most popular approach goes with extraordinary [dry-struct](https://hanakai.org/learn/dry/dry-struct/v1.8) library and Rails Event Store also provides [an example of possible implementation](https://github.com/RailsEventStore/examples/blob/master/scripts/dry-event.rb), which will end up with events defined as:

```ruby
class FooHappened < Event
  attribute :foo_id, Types::UUID
  attribute :value, Types::Integer
end
```

### Communication Between Contexts

Sooner or later you will realize that your system actually contains two different kinds of events - internal and private to a specific context, which most often you want to keep small. And often bigger events for intercommunication between different contexts or systems. Such events are often called [integration events](https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/domain-events-design-implementation#domain-events-versus-integration-events) or [summary events](https://verraes.net/2019/05/patterns-for-decoupling-distsys-summary-event/). The implementation relies on special processes that listen to internal events, collect data, and when specific conditions occur, they create a new integration/summary event that might be sent to another context or system.

## Why You Should Emit Events And What You Don’t Need

* You don’t need DDD to start emitting events
* You don’t need CQRS to start emitting events
* You don’t need Event Sourcing to start emitting events
* You don’t need handlers to start emitting events
* [You don’t have to save](https://twitter.com/kamgrzybek/status/1471756563400605701) emitted events

My personal greatest benefit of events is the influence on the way I think about designing the system. The moment when you have to name the fact that actually happens opens a magic box in your head that unveils edge cases, impacts on other parts of the system, or unknowns that you have to ask the client. It really changes the way you think and communicates with others. It shapes your language.

Not to mention that now you have an audit log for free.

It’s true, that full implementation of Domain-Driven Design with [CQRS])(https://udidahan.com/2009/12/09/clarified-cqrs/) and Event Sourcing is not simple. It requires knowledge, a lot of learning about new patterns (like how to deal with [GDPR](https://railseventstore.org/docs/advanced-topics/gdpr)), experience, and still in some cases [it may be unnecessary](https://udidahan.com/2011/04/22/when-to-avoid-cqrs/).

Still, emitting events is so simple (at least with Rails Event Store) that it’s almost for free, and the benefits are so great that it’s really hard for me to find a reason to not do so. You can simply start with `event_store.publish(SomethingHappened)` and learn about all this complex stuff later, piece by piece, step by step at your own pace without sacrificing anything.

Thank you for reading and see you next time!
