pragma solidity ^0.4.18;

contract FuzzyMatcher {

    mapping(string => BKTreeNode) bkTree; // BT Tree is represented by a map here
    BKTreeNode root; // The root node of the tree
    uint k;

    function FuzzyMatcher() public {
        root = BKTreeNode({ value: "Yanjia Li" });
        bkTree[root.value] = root;
        k = 1; // maxium acceptable edit distance is 1
    }

    struct BKTreeNode {
        string value;
        mapping(uint => string) children;
    }

    function isEmptyString(string str) private pure returns (bool isEmpty) {
        return sha256(str) == sha256("");
    }

    /*
        Add a new name to this BK tree
    */
    function addNewNode(string value) public {
        assert(isEmptyString(bkTree[value].value));
        addNode(root.value, value);
    }

    /*
        Add a new name to this BK tree. Using recusion to find the right spot for insertion.
    */
    function addNode(string next, string value) private {
        uint distance = getEditDistance(value, next);
        if (!isEmptyString(bkTree[next].children[distance])) {
            addNode(bkTree[next].children[distance], value);
        } else {
            bkTree[next].children[distance] = value;
        }
    }

    /*
        Travese the BK tree to find nodes that has edit distance <= 1 with input name
    */
    function getSimilarNode(string target) public returns(string r) {
        BKTreeNode storage curr = root;
        BKTreeNode[] storage queue;
        uint32 pointer = 0;
        while (pointer < queue.length || pointer == 0) {
            uint distance = getEditDistance(target, curr.value);
            // Ideally, we could traverse the BK tree and get all values with edit distance = 1
            // but here we only return the first valid one we encountered
            if (distance <= k) {
                return curr.value;
            }
            uint lower = distance - k > 0 ? distance - k : 1;
            uint upper = distance + k;
            for (uint index = lower; index <= upper; index++) {
                string memory next = curr.children[index];
                if (!isEmptyString(next)) {
                    queue.push(bkTree[next]);
                }
            }
            if (pointer < queue.length) {
                curr = bkTree[queue[pointer].value];
            }
            pointer++;
        }
        return "";
    }
    
    /*
        A Dynamic programming algorithm to calculate the edit distance between two strings efficiently
    */
    function getEditDistance(string src, string dst) pure private returns(uint d) {
        // reutnr edit distance between src and dst
        bytes memory srcBytes = bytes(src);
        bytes memory dstBytes = bytes(dst);
        uint m = srcBytes.length + 1;
        uint n = dstBytes.length + 1;
        uint[][] memory dp;
        for (uint col = 1; col <= n; col++) {
            dp[0][col] = col;
        }
        for (uint i = 1; i <= m; i++) {
            dp[i][0] = i;
            for (uint j = 1; j <= n; j++) {
                dp[i][j] = dp[i - 1][j - 1];
                if (srcBytes[i - 1] != dstBytes[j - 1]) {
                    dp[i][j]++;
                }
                uint min1 = dp[i][j] < dp[i - 1][j] ? dp[i][j] : dp[i - 1][j];
                uint min2 = min1 < dp[i][j - 1] ? min1 : dp[i][j - 1];
                dp[i][j] = min2;
            }
        }
        return dp[m][n];
    }
}