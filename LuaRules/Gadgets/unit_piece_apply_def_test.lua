if not gadgetHandler:IsSyncedCode() then
    return
end

function gadget:GetInfo()
    return {
        name    = "Pieces Apply UnitDef",
        desc    = "Use Pieces Apply by UnitDef",
        author  = "XNTEABDSC",
        date    = "",
        license = "GNU GPL, v2 or later",
        layer   = 0,
        enabled = true --loaded by default?
    }
end

local DynPieceInfos = {
    hoverarty_turret =
    {
        udid=UnitDefNames.hoverarty.id,
        pieces=
        {
            ---@type DynPieceInfo
            hoverarty_turret_turret={
                basePiece = "turret",
                drawPiece = { "turret" },
                children = {
                    aim = {
                        basePiece = "aim",
                    }
                }
            },
            hoverarty_turret_barrel= {
                basePiece = "barrel1",
                drawPiece = { "barrel1" },
                matrixFromParent="turret",
                children = {
                    firepoint = {
                        basePiece = "firepoint1",
                    }
                }
            },
            hoverarty_turret_firepoint={
                basePiece = "firepoint1",
                matrixFromParent="barrel1"
            }
        }
    }
}

local ApplyPieceInfos = {
    [UnitDefNames.spiderlightarty.id] = {
        {
            turret="hoverarty_turret_turret",
            barrel="hoverarty_turret_barrel",
            flare="hoverarty_turret_firepoint",
        }
    }
}

function gadget:Initalize()
    for _,v in pairs(DynPieceInfos) do
        GG.Pieces.CreateDynPieceInfo(v.udid,v.pieces)
    end
end

function gadget:GameFrame(frame)
    if frame==1 then
        for _,v in pairs(DynPieceInfos) do
            GG.Pieces.CreateDynPieceInfo(v.udid,v.pieces)
        end
    end
end

function gadget:UnitCreated(unitId,unitDefId)
    local ApplyPieceInfo=ApplyPieceInfos[unitDefId]
    if ApplyPieceInfo then
        for _, apply in pairs(ApplyPieceInfo) do
            GG.Pieces.ApplyDynPieceInfoNamed(unitId,apply)
        end
    end
end