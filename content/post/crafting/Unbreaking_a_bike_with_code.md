---
title: "Unbreaking a bike with code"
date: 2022-07-21T09:04:50+02:00
tags: ["crafting", "diy", "3d-printing", "jscad", "cad"]
categories: ["crafting"]
draft: false
---

After wanting one for many years, I finally pulled the trigger and bought
a 3D printer as a birthday gift to myself. And it's been a
blast! I've printed everything I've gotten my hands on, but I have had this nagging
feeling that I was just replicating, I wasn't creating.

One (un)lucky day day though, my son broke the chain guard on is bike. I jumped
on the chance to prove myself and took some quick notes and then took a photo of
it because paper always magically disappears for me.

<img src="/guard_chain_sketch.jpg" alt="My notes" width="100%"/>

With all the measurements ready I started researching CAD (computer-aided design) tools, to figure out
which one would be easiest to use. As it turned out, I hated all of them. They
all look pretty slick and have a gazillion features, but the learning curve was
steep and there was so much lingo I didn't understand. I've never really liked
graphical tools anyway to be honest. The mouse is cumbersome to use and the menus are always a nightmare
to navigate. Eventually though I stumbled upon [JSCAD](https://github.com/jscad/OpenJSCAD.org). A piece of software that let's
me write JavaScript that renders a 3d model. Perfect! :D

With some fairly simple code, I could render a cylinder.

```javascript
const jscad = require('@jscad/modeling')
const { cylinder } = jscad.primitives
const mainCircleRadius = 82.5
const mainCircleThickness = 3

function main () {
  return cylinder({
    radius: mainCircleRadius,
    height: mainCircleThickness,
    center: [0,0,mainCircleThickness/2],
    segments: 64
  })
}

module.exports = { main }
```

<img src="/chain_guard_cylinder.png" alt="I made a cylinder" width="100%"/>

So I'm creating a cylinder with my specified radius and height, and I'm defining
the center position of the object to be x=0 and y=0, so in the center. But I'm
putting it up half it's height in the z axis, so the model will lay on z height
0. This makes it easier to plate things in relation to eachother.
The segments parameter defines how many straight segments should be used to
make up the circle. With segments set to 5, we would get a pentagon, with 64
instead we get a fairly smooth circle.

What I actually wanted though was a nice flat circle with a width of 2 cm, so
the next step was to create a hole in the cylinder.

```javascript
const { subtract } = jscad.booleans
const mainCircleRadius = 82.5
const mainCircleWidth = 20
const mainCircleThickness = 3

function generateMainCircle() {
  const mainCircleOuter = cylinder({
    radius: mainCircleRadius,
    height: mainCircleThickness,
    center: [0,0,mainCircleThickness/2],
    segments: 64})
  const mainCircleInner = cylinder({
    radius: mainCircleRadius - mainCircleWidth,
    height: mainCircleThickness,
    center: [0,0,mainCircleThickness/2],
    segments: 64
  })

  return subtract(mainCircleOuter, mainCircleInner)
}
```

I imported the subtract function, added some variables and pulled this into it's
own little function. One big cylinder as before, and a slightly smaller cylinder
and then I simply subtracted the small one from the big one. Behold the hole!

<img src="/chain_guard_circle.png" alt="I made a circle" width="100%"/>

Next I created yet another circle and attached it to the first to make an L shaped rim.
Basically this thing is what creates the guard which keeps the chain in place.


```javascript
const { union } = jscad.booleans

const rimWidth = 3
const rimThickness = 9
const rimRadius = mainCircleRadius - mainCircleWidth + rimWidth

function generateRim() {
  const rimOuter = cylinder({
    radius: rimRadius,
    height: rimThickness,
    center: [0,0,rimThickness/2],
    segments: 64
  })
  const rimInner = cylinder({
    radius: rimRadius - rimWidth,
    height: rimThickness,
    center: [0,0,rimThickness/2],
    segments: 64
  })

  return subtract(rimOuter, rimInner)
}

function main (){
  const mainCircle = generateMainCircle()
  const rim = generateRim()

  return union(mainCircle, rim)
}

```

<img src="/chain_guard_rim.png" alt="Now with a rim" width="100%"/>

So now there is a rim, but this thing needs to be attached to the cog of
the chain somehow. Enter the tooth, and it's "tooth hole". I seriously had no
idea what to call this, but you get the point I hope.


```javascript
const toothCount = 5
const toothRadius = 10
const toothConnectorLength = 10
const toothThickness = 9
const toothConnectorPositionX = (mainCircleRadius - mainCircleWidth) - (toothRadius / 2 )
const toothPositionX = toothConnectorPositionX - (toothConnectorLength / 2) - 2

const nutClearingRadius = 3.75
const nutRadius = 2

function generateTooth() {
  const toothCircle = cylinder({
    radius: toothRadius,
    height: toothThickness,
    center: [toothPositionX,0,toothThickness/2],
    segments: 24
  })
  const toothConnector = cuboid({
    size: [toothConnectorLength,
    toothRadius * 2, toothThickness],
    center: [toothConnectorPositionX,0,toothThickness/2]
  })

  const toothNutClearingHole = cylinder({
    radius: nutClearingRadius,
    height: toothThickness/2,
    center: [toothPositionX,0,toothThickness/4],
    segments: 12
  })
  const toothNutHole = cylinder({
    radius: nutRadius,
    height: toothThickness-2,
    center: [toothPositionX,0,toothThickness - (toothThickness/4)],
    segments: 64
  })

  const tooth = union(toothCircle, toothConnector)
  const nut = union(toothNutClearingHole, toothNutHole)

  return subtract(tooth, nut)
}

function main (){
  const mainCircle = generateMainCircle()
  const rim = generateRim()

  const tooth = generateTooth()

  const single_tooth_chain_guard = union(union(mainCircle, rim), tooth)

  return single_tooth_chain_guard
}
```

<img src="/chain_guard_single_tooth.png" alt="I made a tooth" width="100%"/>

This basically just adds another function which generates a "toothCircle" where
we place the "nut hole" or screw hole I guess would be a better name and the
toothNutClearingHole which is where the head of the screw should fit. To get a
good attachment to the rest of the design I added a cuboid to the circle which
would then fit onto the main body of the chain guard.

Now I just had to copy that tooth out to 4 other spots on the chain guard, which
was surprisingly simple.

```javascript
function main (){
  const mainCircle = generateMainCircle()
  const rim = generateRim()

  const tooth = generateTooth()

  const single_tooth_chain_guard = union(union(mainCircle, rim), tooth)

  const toothAngle = degToRad(360/toothCount)

  var full_chain_guard = single_tooth_chain_guard

  for (let i = 0; i < toothCount; i++) {
    const rotated_chain_guard = rotateZ(toothAngle, full_chain_guard)
    full_chain_guard = union(full_chain_guard, rotated_chain_guard)
  }

  return full_chain_guard

}
```

<img src="/chain_guard_complete.png" alt="And it's done!" width="100%"/>

The for loop rotates our chain guard and adds another tooth for each iteration,
until we finally have all 5 of them.

Now it's just a matter of preparing the model for my printer, and fire it up!

<img src="/guard_chain_printing.jpg" alt="Look at it go!" width="100%"/>

Once it was done I printed another one for the backside and I could finally
attach it. Or at least I'm in the process of doing that here.

<img src="/guard_chain_complete.jpg" alt="Shiny!" width="100%"/>

This was actually much easier and more fun than I had feared. You can view my
JavaScript code in all it's beauty
[here](https://github.com/brujoand/XYZ-models/blob/master/bicycle_chain_guard/bicycle_chain_guard.js)
and Github also supports viewing STLs in the browser so you could also play with
the finished model over
[here](https://github.com/brujoand/XYZ-models/blob/master/bicycle_chain_guard/bicycle_chain_guard.stl)
