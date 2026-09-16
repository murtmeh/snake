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
    // protocol-number, ...
    // 
    // 0,
    // receiver,
    // sender,
    // wall-id,
    // position,
    // snake-length
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
    if (isSnakeOnScreen()) {
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
        tail.set(LedSpriteProperty.X, moveX)
        tail.set(LedSpriteProperty.Y, moveY)
        hetaOrmen.insertAt(1, tail)
        setBrightness()
    }
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
            createSnake(parseFloat(radioRecieve[4]), 0, 90)
        } else if (radioRecieve[3] == "3") {
            direction = 3
            createSnake(parseFloat(radioRecieve[4]), 4, 270)
        } else if (radioRecieve[3] == "2") {
            direction = 2
            createSnake(4, parseFloat(radioRecieve[4]), 180)
        } else {
            direction = 0
            createSnake(0, parseFloat(radioRecieve[4]), 0)
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
    } else {
    	
    }
})
input.onButtonPressed(Button.B, function () {
    if (isSnakeOnScreen()) {
        hetaOrmen[0].turn(Direction.Right, 90)
        direction += 1
        if (direction > 3) {
            direction = 0
        }
    }
})
let radioRecieve: string[] = []
let tail: game.LedSprite = null
let moveY = 0
let moveX = 0
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
snakeLength = 4
let timePaused = 750
direction = 0
hetaOrmen = []
allPlayers = []
alive = true
isInGame = false
thisID = convertToText(randint(1000, 9999))
basic.forever(function () {
    if (isSnakeOnScreen()) {
        moveSnake()
    }
    basic.pause(timePaused)
})
