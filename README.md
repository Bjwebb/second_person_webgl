# Second Person Teapot Jousting Simulator

Demo at http://bjwebb.co.uk/files/teapots/ but you need to pass a suitable hash to specify the 'room' and teapot number.

e.g. the teapots in room a are

http://bjwebb.co.uk/files/teapots/#a_0
http://bjwebb.co.uk/files/teapots/#a_1
http://bjwebb.co.uk/files/teapots/#a_2
http://bjwebb.co.uk/files/teapots/#a_3
http://bjwebb.co.uk/files/teapots/#a_4
http://bjwebb.co.uk/files/teapots/#a_5

Please replace 'a' with a different name, since otherwise it will conflict with other people.

Teapot 0 must be loaded first.

# Technologies

Uses webrtc and webgl, so you must have this availible in your browser, and be connected to a suitably permissive network for this to work. Also note that webrtc data in firefox and chrome aren't compatible, so all players in one game must currently be using the same browser.

# Gameplay

You control a teapot, and must hit other teapots with your spout, without being hit by their spout.

If you hit them without being hit, you win a point. If you both hit each other with your spouts, it's a draw.

But wait, teapots are magical creatures who can't see for themselves, and can only see thing from the perspective of other teapots!
