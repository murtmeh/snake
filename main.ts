function sendDisplayState () {
    displayStateMsg = "1" + ";" + control.deviceSerialNumber()
    for (let displayIndex of hetaOrmen) {
        displayStateMsg = "" + displayStateMsg + ";" + displayIndex.get(LedSpriteProperty.X) + "," + displayIndex.get(LedSpriteProperty.Y) + "," + displayIndex.get(LedSpriteProperty.Brightness)
    }
    displayStateMsg = "" + displayStateMsg + ";"
    radio.sendString(displayStateMsg)
}
function sendButtonPress (button: string) {
    buttonPressMsg = "2" + ";" + control.deviceSerialNumber() + ";" + button + ";"
    radio.sendString(buttonPressMsg)
}
function createSnake () {
    hetaOrmen = []
    alive = true
    SnakeX = 1
    SnakeY = 2
    for (let index = 0; index < snakeLength; index++) {
        newSprite = game.createSprite(SnakeX, SnakeY)
        hetaOrmen.push(newSprite)
        SnakeX += -1
    }
    setBrightness()
}
input.onButtonPressed(Button.A, function () {
    if (!(isRelay)) {
        hetaOrmen[0].turn(Direction.Left, 90)
        direction += -1
        if (direction < 0) {
            direction = 3
        }
        sendButtonPress("A")
    } else {
    	
    }
})
function setBrightness () {
    for (let index = 0; index <= hetaOrmen.length - 1; index++) {
        hetaOrmen[index].set(LedSpriteProperty.Brightness, 255 - index * (255 / snakeLength))
    }
}
function moveSnake () {
    moveX = hetaOrmen[0].get(LedSpriteProperty.X)
    moveY = hetaOrmen[0].get(LedSpriteProperty.Y)
    tail = hetaOrmen.pop()
    moveCheck()
    tail.set(LedSpriteProperty.X, moveX)
    tail.set(LedSpriteProperty.Y, moveY)
    hetaOrmen.reverse()
    head = hetaOrmen.pop()
    hetaOrmen.reverse()
    hetaOrmen.unshift(tail)
    hetaOrmen.unshift(head)
    setBrightness()
}
input.onButtonPressed(Button.AB, function () {
    if (!(isRelay)) {
        sendButtonPress("A+B")
    } else {
    	
    }
})
function moveCheck () {
    if (hetaOrmen[0].get(LedSpriteProperty.X) >= 4 && direction == 0) {
        exitWall = 2
        hetaOrmen[0].set(LedSpriteProperty.X, 0)
    } else if (hetaOrmen[0].get(LedSpriteProperty.X) <= 0 && direction == 2) {
        exitWall = 4
        hetaOrmen[0].set(LedSpriteProperty.X, 4)
    } else if (hetaOrmen[0].get(LedSpriteProperty.Y) <= 0 && direction == 3) {
        exitWall = 1
        hetaOrmen[0].set(LedSpriteProperty.Y, 4)
    } else if (hetaOrmen[0].get(LedSpriteProperty.Y) >= 4 && direction == 1) {
        exitWall = 3
        hetaOrmen[0].set(LedSpriteProperty.Y, 0)
    } else {
        hetaOrmen[0].move(1)
    }
}
radio.onReceivedString(function (receivedString) {
    if (!(isRelay)) {
    	
    } else {
        if (receivedString.charAt(0) != "0") {
            serial.writeLine(receivedString)
        }
    }
})
input.onButtonPressed(Button.B, function () {
    if (!(isRelay)) {
        hetaOrmen[0].turn(Direction.Right, 90)
        direction += 1
        if (direction > 3) {
            direction = 0
        }
        sendButtonPress("B")
    } else {
    	
    }
})
let exitWall = 0
let head: game.LedSprite = null
let tail: game.LedSprite = null
let moveY = 0
let moveX = 0
let newSprite: game.LedSprite = null
let SnakeY = 0
let SnakeX = 0
let alive = false
let buttonPressMsg = ""
let hetaOrmen: game.LedSprite[] = []
let displayStateMsg = ""
let direction = 0
let timePaused = 0
let snakeLength = 0
let isRelay = false
radio.setGroup(69)
if (input.buttonIsPressed(Button.A)) {
    isRelay = true
    basic.showLeds(`
        . . # . .
        . . # . .
        # # # # #
        # . # . #
        # . # . #
        `)
} else {
    isRelay = false
    snakeLength = 4
    timePaused = 750
    direction = 0
    music.setVolume(255)
    createSnake()
}
basic.forever(function () {
    if (!(isRelay)) {
        if (alive == true) {
            moveSnake()
            sendDisplayState()
        }
        basic.pause(timePaused)
    } else {
    	
    }
})
