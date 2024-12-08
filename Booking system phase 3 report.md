Performing a security check of the booking system

1.	What is wrong? -> It allows to book a resource by reserver or administrator if they are under 15 years old.
How did you find it? -> When I registered a user under 15 years and they are allowed to book a resource
How should it work/What should be fixed? -> A reserver (and of course also the administrator) can book a resource if they are over 15 years old. It can be fixed by only registering the user who are over 15 years old

2.	What is wrong? -> The reservers identity is shown when the booking system is logged in by the user
How did you find it? -> When I login to the reservation system
How should it work/What should be fixed? -> The reservation system should allow viewing booked resources without revealing the identity of the reserver. It can be fixed by hiding the reservers identity when the user is logged in

3.	What is wrong? -> After doing zap test, the home page is full of reservation list and cannot access the login option of the home page.
How did you find it? -> after 3 attacks on zap
How should it work/What should be fixed? -> it should be showing normal home page

