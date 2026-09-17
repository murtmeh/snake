// protocol 0: hand the snake to another player
// 
// 0,
// receiverId,
// heading (degrees: 0 up, 90 right, 180 down, 270 left),
// position along the wall,
// snakeLength
function sendSnake (heading: number, exitPos: number) {
    if (allPlayers.length > 0) {
        radio.sendString("0" + "," + allPlayers._pickRandom() + "," + heading + "," + exitPos + "," + snakeLength)
    }
    deleteSnake()
}
function isSnakeOnScreen () {
    return alive == true && hetaOrmen.length != 0
}
function deleteSnake () {
    while (hetaOrmen.length > 0) {
        hetaOrmen.pop().delete()
    }
}
// heading in degrees, same convention as the sprite: 0 up, 90 right, 180 down, 270 left
function createSnake (headX: number, headY: number, heading: number) {
    deleteSnake()
    alive = true
    SnakeX = 0
    SnakeY = 0
    if (heading == 0) {
        SnakeY = -1
    } else if (heading == 90) {
        SnakeX = 1
    } else if (heading == 180) {
        SnakeY = 1
    } else {
        SnakeX = -1
    }
    for (let index = 0; index <= snakeLength - 1; index++) {
        newSprite = game.createSprite(headX - SnakeX * index, headY - SnakeY * index)
        newSprite.set(LedSpriteProperty.Direction, heading)
        hetaOrmen.push(newSprite)
    }
    setBrightness()
}
input.onButtonPressed(Button.A, function () {
    if (isSnakeOnScreen() && buttonPressed == false) {
        buttonPressed = true
        hetaOrmen[0].turn(Direction.Left, 90)
    }
})
function initGame (myId: string) {
    // protocol 3
    // 
    // 3,
    // myId,
    radio.sendString("3" + "," + myId)
    basic.showNumber(3)
    for (let index2 = 0; index2 <= 2; index2++) {
        basic.showNumber(2 - index2)
    }
    createSnake(2, 2, 0)
    createApple()
    radio.sendString("4")
}
function setBrightness () {
    if (isSnakeOnScreen()) {
        for (let index22 = 0; index22 <= hetaOrmen.length - 1; index22++) {
            hetaOrmen[index22].set(LedSpriteProperty.Brightness, 255 - index22 * (255 / snakeLength))
        }
    }
}
function moveSnake () {
    moveX = hetaOrmen[0].get(LedSpriteProperty.X)
    moveY = hetaOrmen[0].get(LedSpriteProperty.Y)
    moveCheck()
    if (isSnakeOnScreen()) {
        tail = hetaOrmen.pop()
        oldTailX = tail.get(LedSpriteProperty.X)
        oldTailY = tail.get(LedSpriteProperty.Y)
        tail.set(LedSpriteProperty.X, moveX)
        tail.set(LedSpriteProperty.Y, moveY)
        hetaOrmen.insertAt(1, tail)
        setBrightness()
        kollakolission()
    }
}
function addSnake () {
    newSprite = game.createSprite(oldTailX, oldTailY)
    snakeLength += 1
    hetaOrmen.push(newSprite)
    setBrightness()
}
function createApple () {
    AppleNotPlaced = true
    while (AppleNotPlaced) {
        appleX = randint(0, 4)
        appleY = randint(0, 4)
        AppleNotPlaced = false
        for (let snakePart = 0; snakePart <= hetaOrmen.length - 1; snakePart++) {
            if (hetaOrmen[snakePart].get(LedSpriteProperty.X) == appleX && hetaOrmen[snakePart].get(LedSpriteProperty.Y) == appleY) {
                AppleNotPlaced = true
            }
        }
    }
    apple = game.createSprite(appleX, appleY)
    apple.set(LedSpriteProperty.Blink, 250)
    appleExists = true
}
input.onButtonPressed(Button.AB, function () {
    if (!(isInGame)) {
        isInGame = true
        initGame(thisID)
    }
})
// //      0
// //    #####
// // 270 ##### 90
// //    #####
// //     180
function moveCheck () {
    if (isSnakeOnScreen()) {
        heading = getHeading()
        if (heading == 90 && hetaOrmen[0].get(LedSpriteProperty.X) >= 4) {
            sendSnake(heading, hetaOrmen[0].get(LedSpriteProperty.Y))
        } else if (heading == 270 && hetaOrmen[0].get(LedSpriteProperty.X) <= 0) {
            sendSnake(heading, hetaOrmen[0].get(LedSpriteProperty.Y))
        } else if (heading == 0 && hetaOrmen[0].get(LedSpriteProperty.Y) <= 0) {
            sendSnake(heading, hetaOrmen[0].get(LedSpriteProperty.X))
        } else if (heading == 180 && hetaOrmen[0].get(LedSpriteProperty.Y) >= 4) {
            sendSnake(heading, hetaOrmen[0].get(LedSpriteProperty.X))
        } else {
            hetaOrmen[0].move(1)
        }
    }
}
radio.onReceivedString(function (receivedString) {
    radioRecieve = receivedString.split(",")
    if (radioRecieve[0] == "0" && radioRecieve[1] == thisID) {
        // the snake keeps its heading, so the heading alone says which wall it enters from
        snakeLength = parseFloat(radioRecieve[4])
        heading = parseFloat(radioRecieve[2])
        exitPos = parseFloat(radioRecieve[3])
        if (alive) {
            if (heading == 0) {
                createSnake(exitPos, 4, 0)
            } else if (heading == 90) {
                createSnake(0, exitPos, 90)
            } else if (heading == 180) {
                createSnake(exitPos, 0, 180)
            } else {
                createSnake(4, exitPos, 270)
            }
        } else {
            // already dead: pass the snake along untouched instead of taking it
            sendSnake(heading, exitPos)
        }
    } else if (radioRecieve[0] == "3" && isInGame) {
        if (allPlayers.indexOf(radioRecieve[1]) == -1) {
            allPlayers.push(radioRecieve[1])
        }
    } else if (radioRecieve[0] == "3" && !(isInGame)) {
        isInGame = true
        if (allPlayers.indexOf(radioRecieve[1]) == -1) {
            allPlayers.push(radioRecieve[1])
        }
        basic.showIcon(IconNames.Yes)
        basic.pause(randint(100, 500))
        radio.sendString("3" + "," + thisID)
    } else if (radioRecieve[0] == "4") {
        basic.clearScreen()
        createApple()
    } else {
    	
    }
})
input.onButtonPressed(Button.B, function () {
    if (isSnakeOnScreen() && buttonPressed == false) {
        buttonPressed = true
        hetaOrmen[0].turn(Direction.Right, 90)
    }
})
input.onGesture(Gesture.Shake, function () {
    if (appleExists) {
        apple.delete()
        createApple()
    }
})
// the sprite reports left as -90, so normalise to 0..359
function getHeading () {
    return (hetaOrmen[0].get(LedSpriteProperty.Direction) + 360) % 360
}
function kollakolission () {
    i = 1
    for (let index = 0; index < snakeLength - 1; index++) {
        if (hetaOrmen[0].get(LedSpriteProperty.X) == hetaOrmen[i].get(LedSpriteProperty.X) && hetaOrmen[0].get(LedSpriteProperty.Y) == hetaOrmen[i].get(LedSpriteProperty.Y)) {
            alive = false
            basic.clearScreen()
            basic.showIcon(IconNames.Skull)
            // pass the snake on to another player instead of letting it vanish
            heading = getHeading()
            if (heading == 90 || heading == 270) {
                sendSnake(heading, hetaOrmen[0].get(LedSpriteProperty.Y))
            } else {
                sendSnake(heading, hetaOrmen[0].get(LedSpriteProperty.X))
            }
            return
        }
        i += 1
    }
}
let points = 0
let i = 0
let exitPos = 0
let radioRecieve: string[] = []
let heading = 0
let appleExists = false
let apple: game.LedSprite = null
let appleY = 0
let appleX = 0
let AppleNotPlaced = false
let oldTailY = 0
let oldTailX = 0
let tail: game.LedSprite = null
let moveY = 0
let moveX = 0
let buttonPressed = false
let newSprite: game.LedSprite = null
let SnakeY = 0
let SnakeX = 0
let thisID = ""
let isInGame = false
let alive = false
let allPlayers: string[] = []
let hetaOrmen: game.LedSprite[] = []
let snakeLength = 0
radio.setGroup(69)
snakeLength = 2
let timePaused = 750
hetaOrmen = []
allPlayers = []
alive = true
isInGame = false
thisID = convertToText(randint(1000, 9999))
basic.forever(function () {
    if (isSnakeOnScreen()) {
        moveSnake()
        if (isSnakeOnScreen() && appleExists && hetaOrmen[0].isTouching(apple)) {
            apple.delete()
            points += 1
            addSnake()
            createApple()
        }
    }
    buttonPressed = false
    basic.pause(timePaused)
})
