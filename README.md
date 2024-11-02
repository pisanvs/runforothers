# Run For Others - LINTAC

Run for others is an institutional CAS proyect at my school,
it follows a tradition that was left behind a long time ago.

## About

It consists of students, parents and the greater school
community running laps around the school and donating a
certain amount of money to a charity for each lap.

The event seeks to bring the community together through
collective charitable actions.

I offered to create the system for tracking the runners
around the track, so I got to work and this is what came out
of it. Behold the all-in-one charity marathon app!

## Tech Stack Used

Originally, the idea was to have some QR code scanning 
"satellites", I wanted to code these in flutter since I
didn't know how to use it and have been wanting to learn for
a long time. Then the rest of the system would be in a
NextJS webapp (I'm much more familiar with Next & React).
But once I actually started coding and understanding Dart &
Flutter, I ended up implementing everything within Flutter
(this is the reason behind the weird folder structure)

So, final Tech Stack:

- Flutter
- Supabase as DB

I actually learned about Supabase in a meetup/conference
they held alongside CodeGPT in Chile. It probably was one
of my best discoveries. I was previously a MongoDB/NoSQL
fanboy (childish behavior i know), now I am just fascinated
with the speed of Supabase from the dev side AND from the
user POV too.

## Functionality

1. The app lets you login with a magic link
2. From supabase the admin is supposed to grant roles to
each user
3. Depending on the roles, the user will be able to see the
different pages:
    * Runner sign up: Will let you print the QR Tag for
    each runner, as well as input their data.
    * Set station: Select the station and track for
    each of the satellites. Also allows for creation of new
    ones.
    * Scan: Set the satellite on a good vantage point in
    order to scan each of the runners qr codes as they run
    by.
    * Standings: Here you can see the leaderboard.