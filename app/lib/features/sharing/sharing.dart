/// Safe-share module public API: send designs on WhatsApp (or any app).
library;

export 'application/product_sharer.dart'
    show ProductSharer, ShareOptions, ShareOutcome, productSharerProvider, sharingRepositoryProvider;
export 'domain/sharing.dart' show ShareableProduct, SharingRepository;
export 'presentation/share_flow.dart' show buildShareCaption, shareDesigns;
