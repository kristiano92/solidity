pragma solidity ^0.4.1;
// Contract allows transfers in payment channel.
contract PaymentChannel {

		address public channelSender;
		address public channelReceiver;
		uint public beginDate;
		uint public channelTimeout;
		mapping (bytes32 => address) signatures;

		// This is constructor which opens channel and sets receiver and time.
		function PaymentChannel(address to, uint timeout) payable {
			channelReceiver = to;
			channelSender = msg.sender;
			beginDate = now;
			channelTimeout = timeout;
		}

	  // It is used to close a channel and send funds.
		function CloseChannel(bytes32 h, uint8 v, bytes32 r, bytes32 s, uint value){

			address signer;
			bytes32 proof;

			// Get a signer from signature.
			signer = ecrecover(h, v, r, s);

			// Signature is invalid, throw.
			if (signer != channelSender && signer != channelReceiver) throw;

			proof = sha3(this, value);

			// Signature is valid but doesn't match the data provided.
			if (proof != h) throw;

			if (signatures[proof] == 0)
				signatures[proof] = signer;
			else if (signatures[proof] != signer){
				// Channel is completed, both of signatures were provided.
				!channelReceiver.transfer(value);
				selfdestruct(channelSender);
			}
		}
		// If time ends, it destroys contract and returns sender's funds.
		function ChannelTimeout(){
			if (beginDate + channelTimeout > now)
				revert();

			selfdestruct(channelSender);
		}
}
