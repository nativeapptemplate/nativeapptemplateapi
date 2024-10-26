class Api::Shopkeeper::BasePolicy
  attr_reader :accounts_shopkeeper, :record

  def initialize(accounts_shopkeeper, record)
    raise Pundit::NotAuthorizedError, "must be signed in" unless accounts_shopkeeper

    @accounts_shopkeeper = accounts_shopkeeper
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  class Scope
    def initialize(accounts_shopkeeper, scope)
      raise Pundit::NotAuthorizedError, "must be signed in" unless accounts_shopkeeper

      @accounts_shopkeeper = accounts_shopkeeper
      @scope = scope
    end

    def resolve
      scope.all
    end

    private

    attr_reader :accounts_shopkeeper, :scope
  end
end
