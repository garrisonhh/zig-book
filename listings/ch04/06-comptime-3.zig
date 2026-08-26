//! Listing 4.6 Using our parser

const words = blk: { 
    @setEvalBranchQuota(1_000_000); 
    break :blk parseWordlist(@embedFile("words.txt")); 
};