/// Customers module public API.
library;

export 'application/customer_providers.dart'
    show customerDetailProvider, customerListProvider, customerRepositoryProvider, regularMaalProvider;
export 'domain/customers.dart'
    show
        CustomerDetail,
        CustomerQuery,
        CustomerRate,
        CustomerRepository,
        CustomerSort,
        CustomerSummary,
        ProductRef,
        RegularMaalItem;
export 'presentation/customer_detail_screen.dart' show CustomerActions, CustomerDetailScreen, customerActionsProvider;
export 'presentation/customer_edit_screen.dart' show CustomerEditScreen;
export 'presentation/customer_rates_screen.dart' show CustomerRatesScreen;
export 'presentation/customers_screen.dart' show CustomersScreen;
