function sendSnake (receiver: string, localWall: number, localExitPos: number) {
    if (localWall == 1) {
        exitWall = 3
    } else if (localWall == 2) {
        exitWall = 4
    } else if (localWall == 3) {
        exitWall = 1
    } else {
        exitWall = 2
    }
    if (allPlayers.length > 0) {
        radio.sendString("0" + "," + allPlayers._pickRandom() + "," + thisID + "," + exitWall + "," + localExitPos + "," + snakeLength)
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
function createSnake (headX: number, headY: number, spriteDir: number) {
    deleteSnake()
    alive = true
    SnakeX = 0
    SnakeY = 0
    if (spriteDir == 0) {
        SnakeX = 1
    } else if (spriteDir == 90) {
        SnakeY = 1
    } else if (spriteDir == 180) {
        SnakeX = -1
    } else {
        SnakeY = -1
    }
    for (let index = 0; index <= snakeLength - 1; index++) {
        newSprite = game.createSprite(headX - SnakeX * index, headY - SnakeY * index)
        newSprite.set(LedSpriteProperty.Direction, spriteDir)
        hetaOrmen.push(newSprite)
    }
    setBrightness()
}
input.onButtonPressed(Button.A, function () {
    if (isSnakeOnScreen() && buttonPressed == false) {
        buttonPressed = true
        hetaOrmen[0].turn(Direction.Left, 90)
        direction += -1
        if (direction < 0) {
            direction = 3
        }
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
    isInGame = true
    initGame(thisID)
})
// //     1
// //   #####
// // 4 ##### 2
// //   #####
// 3
// 0 is "not specified"
function moveCheck () {
    if (isSnakeOnScreen()) {
        if (hetaOrmen[0].get(LedSpriteProperty.X) >= 4 && direction == 0) {
            sendSnake("0", 2, hetaOrmen[0].get(LedSpriteProperty.Y))
        } else if (hetaOrmen[0].get(LedSpriteProperty.X) <= 0 && direction == 2) {
            sendSnake("0", 4, hetaOrmen[0].get(LedSpriteProperty.Y))
        } else if (hetaOrmen[0].get(LedSpriteProperty.Y) <= 0 && direction == 3) {
            sendSnake("0", 1, hetaOrmen[0].get(LedSpriteProperty.X))
        } else if (hetaOrmen[0].get(LedSpriteProperty.Y) >= 4 && direction == 1) {
            sendSnake("0", 3, hetaOrmen[0].get(LedSpriteProperty.X))
        } else {
            hetaOrmen[0].move(1)
        }
    }
}
radio.onReceivedString(function (receivedString) {
    radioRecieve = receivedString.split(",")
    if (radioRecieve[0] == "0" && radioRecieve[1] == thisID) {
        // if packet[3], which is the wall is 1, 3, 2 or implied 4, spawn the snake accordingly
        snakeLength = parseFloat(radioRecieve[5])
        if (radioRecieve[3] == "1") {
            direction = 1
            createSnake(parseFloat(radioRecieve[4]), 0, 180)
        } else if (radioRecieve[3] == "3") {
            direction = 3
            createSnake(parseFloat(radioRecieve[4]), 4, 0)
        } else if (radioRecieve[3] == "2") {
            direction = 2
            createSnake(4, parseFloat(radioRecieve[4]), 270)
        } else {
            direction = 0
            createSnake(0, parseFloat(radioRecieve[4]), 90)
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
        direction += 1
        if (direction > 3) {
            direction = 0
        }
    }
})
input.onGesture(Gesture.Shake, function () {
    if (appleExists) {
        apple.delete()
        createApple()
    }
})
function kollakolission () {
    i = 1
    for (let index = 0; index < snakeLength - 1; index++) {
        if (hetaOrmen[0].get(LedSpriteProperty.X) == hetaOrmen[i].get(LedSpriteProperty.X) && hetaOrmen[0].get(LedSpriteProperty.Y) == hetaOrmen[i].get(LedSpriteProperty.Y)) {
            alive = false
            basic.clearScreen()
            basic.showIcon(IconNames.Skull)
        }
        i += 1
    }
}
let points = 0
let i = 0
let radioRecieve: string[] = []
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
let exitWall = 0
let thisID = ""
let isInGame = false
let alive = false
let allPlayers: string[] = []
let hetaOrmen: game.LedSprite[] = []
let direction = 0
let snakeLength = 0
radio.setGroup(69)
snakeLength = 2
let timePaused = 750
direction = 3
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
